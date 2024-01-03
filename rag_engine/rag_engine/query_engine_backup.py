# from .vdb import *
from graph2doc import *
from openai import OpenAI

client = OpenAI()
import os
import sys
import json
import logging
from .vdb import *

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

logger = logging.getLogger(__name__)

# TODO: add jaseci actions to set system and user instructions
STORAGE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "storage", "{user}.json"
)


class QueryEngine:
    # configuration for the rules based graph2doc
    rules_entity_keys = {}
    rules_embed_props = {}
    rules_name_mappings = {}

    # configuration for the generative AI based graph2doc
    gen_description = ""
    gen_examples = []
    gen_fields = []

    def __init__(self, graph2doc="rules", llm="gpt-3.5-turbo-0613"):
        self.vdb = None
        self.configure_graph2doc(graph2doc=graph2doc)
        self.llm = llm

    def configure_vdb(self, vdb_path=None):
        self.vdb = VectorDB(vdb_path)

    def clear_vdb(self, user):
        self.vdb.clear_collection(user)

    def configure_graph2doc(self, graph2doc):
        self.graph2doc = Graph2Doc.create(method=graph2doc)
        self.graph2doc_method = graph2doc

    def _subgraph2docs(self, subgraphs):
        # generate natural language documents for subgraphs
        if self.graph2doc_method == "rules":
            kwargs = {
                "entity_keys": self.rules_entity_keys,
                "embed_props": self.rules_embed_props,
                "name_mappings": self.rules_name_mappings,
                "llm": self.llm,
            }
        elif self.graph2doc_method == "gen":
            kwargs = {
                "description": self.gen_description,
                "examples": self.gen_examples,
                "fields": self.gen_fields,
                "llm": self.llm,
            }
        else:
            # custom
            kwargs = {}

        logger.info(self.graph2doc_method + " graph2docmethod")
        documents, ids = self.graph2doc.convert(subgraphs=subgraphs, **kwargs)
        return documents, ids

    def push_subgraph(self, user, subgraphs, overwrite=False):
        """
        Push a subgraph and its natural language document to storage
        """
        documents, ids = self._subgraph2docs(subgraphs)
        updates = {id_: doc for id_, doc in zip(ids, documents)}

        if self.vdb:
            print("Storing in vdb")
            # Store in vector database
            self.vdb.upsert(user=user, ids=ids, documents=documents)
        else:
            print("Storing in JSON file")
            # store in json files
            # load in if it already exists
            storage_json = STORAGE_PATH.format(user=user)
            if not overwrite:
                with open(storage_json, "r") as f:
                    storage = json.load(f)

                storage.update(updates)
            else:
                storage = updates

            # save to storage
            # Create the directory if it does not exist
            if not os.path.exists(os.path.dirname(storage_json)):
                os.makedirs(os.path.dirname(storage_json))

            with open(storage_json, "w") as f:
                json.dump(storage, f, indent=2)

    def query_with_vdb(
        self,
        user,
        query,
        system_inst,
        user_inst,
        use_prior_knowledge=False,
        llm=None,
        n_results=10,
    ):
        """
        query with vector DB
        """
        logger.info("--------Querying with vector DB--------")

        # load documents from storage
        documents = self.vdb.get_docs(user=user, query=query, n_results=n_results)
        documents = documents["documents"][0]
        logger.info(f"Documents are retrieved from VDB: {len(documents)}")

        context_str = "\n".join(documents)

        system_prompt = (
            f"{system_inst}\n"
            f"Always answer the query using the provided context information, "
            f"and {'prior knowledge when applicable' if use_prior_knowledge else 'not prior knowledge.'}\n"
            f"Some rules to follow:\n"
            f"1. Never directly reference the given context in your answer.\n"
            f"2. Avoid statements like 'Based on the context, ...' or "
            f"'The context information ...' or anything along "
            f"those lines."
        )
        user_prompt = (
            f"Context information is below.\n"
            f"---------------------\n"
            f"{user_inst}\n"
            f"{context_str}\n"
            f"---------------------\n"
            f"Given the context information, "
            f"answer the query.\n"
            f"Query: {query}\n"
            f"Answer: "
        )

        one_prompt = system_prompt + "\n" + user_prompt

        messages = [
            # {"role": "system", "content": system_prompt},
            {
                "role": "user",
                # "content": one_prompt.format(context_str=context_str, query=query),
                "content": one_prompt,
            },
        ]

        logger.info("--------Querying LLM--------")
        logger.info(messages)
        llm = llm if llm else self.llm
        completion = client.chat.completions.create(
            model=llm, messages=messages, temperature=0.5
        )
        responses = [c.message for c in completion.choices]
        logger.info(responses[0]["content"])

        return responses[0]["content"]

    def query_with_subgraph(
        self,
        user,
        subgraphs,
        query,
        system_inst,
        user_inst,
        use_prior_knowledge=False,
        llm=None,
    ):
        """
        Query with a subgraph, without vector db
        """
        logger.info("--------Querying with subgraph--------")

        # load documents from storage
        documents = []
        # try:
        #     with open(STORAGE_PATH.format(user=user), "r") as f:
        #         storage = json.load(f)

        #     # Get ids from subgraphs
        #     ids = []
        #     for chain in subgraphs:
        #         ids.extend([obj["jid"] for obj in chain])

        #     for id_ in ids:
        #         if id_ in storage:
        #             documents.append(storage[id_])
        # except:
        # no stored documents
        # construct the documents live
        documents, _ = self._subgraph2docs(subgraphs)

        context_str = "\n".join(documents)

        system_prompt = (
            f"{system_inst}\n"
            f"Always answer the query using the provided context information, "
            f"and {'prior knowledge when applicable' if use_prior_knowledge else 'not prior knowledge.'}\n"
            f"Some rules to follow:\n"
            # f"1. Never directly reference the given context in your answer.\n"
            f"1. Avoid statements like 'Based on the context, ...' or "
            f"'The context information ...' or anything along "
            f"those lines."
        )
        user_prompt = (
            f"Context information is below.\n"
            f"---------------------\n"
            f"{user_inst}\n"
            f"{context_str}\n"
            f"---------------------\n"
            f"Given the context information, "
            f"answer the query.\n"
            f"Query: {query}\n"
            f"Answer: "
        )

        one_prompt = system_prompt + "\n" + user_prompt

        messages = [
            # {"role": "system", "content": system_prompt},
            {
                "role": "user",
                # "content": one_prompt.format(context_str=context_str, query=query),
                "content": one_prompt,
            },
        ]

        logger.info("--------Querying LLM--------")
        logger.info(messages)
        llm = llm if llm else self.llm
        completion = client.chat.completions.create(
            model=llm, messages=messages, temperature=0.5
        )
        logger.info(completion)
        response = completion.choices[0].message.content
        logger.info(response)
        # responses = [c.message for c in completion.choices]
        # logger.info(responses)
        # logger.info(responses[0]["content"])

        return {"prompt": one_prompt, "response": response}
