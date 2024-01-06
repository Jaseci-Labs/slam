import unittest
import json
import os
from pprint import pprint
from graph_query.graph2doc import Graph2DocGen, Graph2DocCustomMyca
from graph2doc_test_config import DESCRIPTION, EXAMPLES


class TestGraph2Doc(unittest.TestCase):
    def setUp(self):
        self.graph2doc_gen = Graph2DocGen()
        self.graph2doc_custom = Graph2DocCustomMyca()
        self.test_fixture = [
            "myca_day_and_workette",
            "myca_day_and_workset",
            "myca_workset_and_focused_workette",
            "myca_workset_and_ritual",
            "myca_workset_and_workette",
        ]
        self.llm = "gpt-3.5-turbo-0613"

    def test_convert_custom_myca(self):
        for fixture in self.test_fixture:
            print("\n\nTesting fixture: {}".format(fixture))

            fixture_json = os.path.join(
                os.path.dirname(os.path.abspath(__file__)), f"fixtures/{fixture}.json"
            )
            with open(fixture_json, "r") as f:
                subgraphs = json.load(f)

            result = self.graph2doc_custom.convert(
                subgraphs=[subgraphs],
                llm=self.llm,
            )

            print("-----------------")
            # print(subgraphs)
            pprint(result, indent=2)
            print("-----------------")

    def test_convert_gen(self):
        for fixture in self.test_fixture:
            print("\n\nTesting fixture: {}".format(fixture))

            fixture_json = os.path.join(
                os.path.dirname(os.path.abspath(__file__)), f"fixtures/{fixture}.json"
            )
            with open(fixture_json, "r") as f:
                subgraphs = json.load(f)

            result = self.graph2doc_gen.convert(
                subgraphs=[subgraphs],
                description=DESCRIPTION,
                examples=EXAMPLES,
                llm=self.llm,
            )

            print("-----------------")
            # print(subgraphs)
            pprint(result, indent=2)
            print("-----------------")

        # self.assertIsInstance(result, str)
        # self.assertGreater(len(result), 0)

    # def test_convert_empty_subgraphs(self):
    #     subgraphs = []
    #     description = "This is a test description"
    #     example_json = {"jsons": [], "docs": []}
    #     llm = "gpt-3.5-turbo-0613"

    #     result = self.graph2doc_gen.convert(
    #         subgraphs=subgraphs,
    #         description=description,
    #         example_json=example_json,
    #         llm=llm,
    #     )

    #     self.assertIsInstance(result, str)
    #     self.assertEqual(len(result), 0)

    # def test_convert_invalid_subgraphs(self):
    #     subgraphs = [
    #         {
    #             "nodes": [
    #                 {"id": "1", "type": "Person", "name": "Alice"},
    #                 {"id": "2", "type": "Person", "name": "Bob"},
    #             ],
    #             "edges": [{"source": "1", "target": "2", "type": "knows"}],
    #         },
    #         {"invalid": "subgraph"},
    #     ]
    #     description = "This is a test description"
    #     example_json = {"jsons": [], "docs": []}
    #     llm = "gpt-3.5-turbo-0613"

    #     with self.assertRaises(ValueError):
    #         self.graph2doc_gen.convert(
    #             subgraphs=subgraphs,
    #             description=description,
    #             example_json=example_json,
    #             llm=llm,
    #         )


if __name__ == "__main__":
    unittest.main()
