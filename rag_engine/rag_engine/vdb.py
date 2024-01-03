__import__(("pysqlite3"))
import sys

sys.modules["sqlite3"] = sys.modules.pop("pysqlite3")

import chromadb
import logging

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger()


def _process_user_id(jid):
    return jid.lstrip("urn:uuid:")


class VectorDB:
    def __init__(self, vdb_path=None):
        # TODO: make the many name mappings state in here
        # Collection should be per user/master
        # chroma_client = chromadb.Client()
        if vdb_path:
            logger.info("Init vdb client with persistent path at " + vdb_path)
            self.chroma_client = chromadb.PersistentClient(path=vdb_path)
        else:
            # in memory mode
            logger.info("Init vdb with in memory mode")
            self.chroma_client = chromadb.Client()

    def clear_collection(self, collection_name):
        """
        Reset a collection
        """
        try:
            self.chroma_client.delete_collection(_process_user_id(collection_name))
        except ValueError:
            logger.info(
                f"Collection not found {_process_user_id(collection_name)}. Skipping deletion."
            )

    def get_or_create_collection(self, collection_name):
        # clean up the user jid to be used as collection name
        collection = self.chroma_client.get_or_create_collection(
            _process_user_id(collection_name)
        )
        return collection

    def upsert(self, user, ids, documents):
        """
        Add or update a list of documents to the vdb
        user: master jid of the user. this will be used as the collection name in the vdb
        ids: list of ids (node and edge ids)
        documents: natural language documents for those nodes/edges
        """
        collection = self.get_or_create_collection(user)
        collection.upsert(ids=ids, documents=documents)
        logger.info(f"Documents are upserted to collection: {len(documents)}")

    def get_docs(self, user, query, n_results=10):
        """
        Query the vector DB to get documents related to the given query
        """
        collection = self.get_or_create_collection(user)
        res = collection.query(
            query_texts=[query],
            n_results=n_results,
        )
        return res

    # def add_subgraph_to_collection(
    #     self,
    #     master,
    #     chains=[],
    #     entity_keys={},
    #     embed_props={},
    #     name_mappings={},
    # ):
    #     """
    #     Add subgrpah to collections.
    #     Subgraphs could be a list of triplets or longer node chains.
    #     For example, [(a, ->, b)] or [(a, ->, b, -> c)]
    #     a, ->, b in this case are jaseci objects full context, which will have properties
    #     entity_keys is the key in the context that will be used as the main name of the node entity.
    #     embed_props is the list of properties from the context of the node that should be embedded. By default, we will embed nothing.
    #     For now, we will go with triplets only approach.
    #     We will convert everything in the chains to natural language documents.
    #     For example, (a (workette), -[parent]->, b) will be converted to document as "a is the parent of b. a is a task with the name blah and note of blah"
    #     name_mappings is an optional mapping for use different names in the embedding generations than the node and edge name in the jac program.
    #     For example, workette --> task, group --> task group
    #     """
    #     # TODO: anything to save in the metadata field?
    #     # TODO: How to handle update.

    #     collection = self.get_or_create_collection(collection_name=master)
    #     documents, ids = self.triplets_to_documents(
    #         chains=chains,
    #         entity_keys=entity_keys,
    #         embed_props=embed_props,
    #         name_mappings=name_mappings,
    #     )

    #     # TODO: bulk upsert or in chunks?
    #     collection.upsert(
    #         ids=[subject["jid"], object_["jid"], predicate["jid"]],
    #         documents=[subject_doc, object_doc, predicate_doc],
    #     )
