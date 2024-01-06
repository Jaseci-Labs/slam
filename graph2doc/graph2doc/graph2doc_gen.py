from .graph2doc import Graph2Doc


class Graph2DocGen(Graph2Doc):
    """
    Convert subgraphs to a document using generative AI models
    """

    def __init__(self) -> None:
        super().__init__()

    def convert(
        self,
        subgraphs,
        description="",
        examples=[],
        fields=[],
        llm="gpt-3.5-turbo-0613",
    ):
        newline = "\n"
        documents = []
        ids = []

        # Filter out fields in examples
        for ex in examples:
            for ex_json in ex["jsons"]:
                ex_json["context"] = dict(
                    (k, v) for k, v in ex_json["context"].items() if k in fields
                )

        for chain in subgraphs:
            # Filter out the fields that are not needed
            new_chain = []
            for item in chain:
                item["context"] = dict(
                    (k, v) for k, v in item["context"].items() if k in fields
                )
                new_chain.append(item)
            chain = new_chain

            system_prompt = (
                "I am giving you a list of three json objects. They are describing a triplet in a graph. A triplet is a set of two nodes and the edge connecting them.\n"
                " The first and third object each describes a node in the graph and the second object describes the edge between the two nodes.\n"
                " The jid field is the UUID of the nodes and the edge.\n"
                " I want you to convert this triplet into three natural language sentences, where two sentences describe the nodes and one sentence describes the edge.\n"
                " Put each description on a separate line and avoid numbering them.\n"
            )

            user_prompt = (
                f"{description}\n"
                f"---------------------\n"
                f"Below are some examples:\n"
                f"---------------------\n"
            )
            for ex in examples:
                user_prompt += (
                    f"For the following JSON:\n"
                    f"{ex['jsons']}\n"
                    f"You should generate the following output:\n"
                    f"{newline.join(ex['docs'])}\n"
                    f"---------------------\n"
                )
            user_prompt += (
                f"Given the above descriptions and example, convert the following JSON into natural language.\n"
                f"{chain}\n"
                f"The natural language documents:\n"
            )

            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ]

            logger.debug("--------Querying LLM--------")
            logger.debug(messages)

            completion = openai.ChatCompletion.create(
                model=llm, messages=messages, temperature=0.5
            )
            responses = [c.message for c in completion.choices]

            # Split the response into a list of documents
            docs = responses[0]["content"].split("\n")
            if len(docs) == 2:
                # Assume that the two lines are for the two nodes, and the edge is described in one of the two
                docs.insert(1, "")

            if len(docs) != 3:
                logger.info(
                    f"LLM response is not in the correct format. Expected 3 lines, got {len(docs)} lines"
                )
                logger.info(docs)
                exit(1)
                continue

            subject, predicate, object_ = chain
            subject_doc, object_doc, predicate_doc = docs

            if subject["jid"] not in ids:
                documents.append(subject_doc)
                ids.append(subject["jid"])

            if object_["jid"] not in ids:
                documents.append(object_doc)
                ids.append(object_["jid"])

            if predicate["jid"] not in ids:
                documents.append(predicate_doc)
                ids.append(predicate["jid"])

        return documents, ids
