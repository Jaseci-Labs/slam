from graph2doc.graph2doc import Graph2Doc

"""
Custom graph2doc for the myca AI feature: new user peptalk
Input is a list of root level workette nodes
"""


class Graph2DocCustomMycaNewUserPeptalk(Graph2Doc):
    def __init__(self) -> None:
        super().__init__()

    def convert(self, subgraphs):
        """
        Given a list of root level workettes, generate a natural language document describing it
        """

        documents = []

        documents.append(
            "I am a new user to the Myca productivity platform. This is my first day using Myca."
        )
        documents.append("I just created the following tasks:")

        doc = "\n"
        tasks = [wkt["context"]["name"] for wkt in subgraphs]
        doc += "\n".join(tasks)

        documents.append(doc)

        return documents, []
