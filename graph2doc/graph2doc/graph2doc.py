from abc import ABC, abstractmethod
import sys
import copy
import logging
import importlib

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

logger = logging.getLogger(__name__)


def snake_to_camel(snake_str):
    components = snake_str.split("_")
    # Capitalize the first letter of each component and join them together
    return "".join(x.title() for x in components)


class Graph2Doc(ABC):
    @abstractmethod
    def convert(self, graph):
        """
        Convert a graph to a document
        """
        pass

    @classmethod
    def create(cls, method):
        method_camel = snake_to_camel(method.lower())
        try:
            module = importlib.import_module(
                f".graph2doc_{method.lower()}", package="graph2doc"
            )
            graph2doc_class = getattr(module, f"Graph2Doc{method_camel}")
            return graph2doc_class()
        except Exception as e:
            raise ValueError(f"Invalid Graph2Doc method: {method}. {e}")
