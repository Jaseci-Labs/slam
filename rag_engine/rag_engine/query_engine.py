from abc import ABC, abstractmethod
import importlib
import json

from langchain.chat_models import ChatOpenAI, ChatOllama
from langchain.globals import set_verbose, set_debug
from langchain.llms import LlamaCpp

set_verbose(True)
set_debug(True)


class QueryEngine(ABC):
    config_vars = []

    @classmethod
    def create(cls, engine_name):
        """Create a query engine from a name"""
        try:
            module = importlib.import_module(
                f".engines.{engine_name}", package="rag_engine"
            )
            engine_class = getattr(module, f"{engine_name.capitalize()}")
            return engine_class()
        except Exception as e:
            raise ValueError(f"Invalid query engine name: {engine_name}. {e}")

    @abstractmethod
    def query(self, payload):
        """Processing a query"""
        pass

    def save(self, path=""):
        """Save the query engine configuration"""
        config = {}
        for var in self.config_vars:
            if not hasattr(self, var):
                raise ValueError(f"Missing config variable: {var}")
            else:
                config[var] = getattr(self, var)
        config["config_vars"] = self.config_vars

        if path:
            with open(path, "w") as f:
                json.dump(config, f, indent=2)

        return config

    def load(self, config):
        """Load the query engine configuration"""
        config_vars = config.pop("config_vars")
        for var in config_vars:
            setattr(self, var, config[var])

        self.init_engine()

    def load_chat_model(self, provider_name, model_name):
        """Load a chat model"""
        if provider_name == "openai":
            return ChatOpenAI(model_name=model_name)
        elif provider_name == "ollama":
            return ChatOllama(model=model_name)
        elif provider_name == "llama.cpp":
            return LlamaCpp(model=model_name)

    @abstractmethod
    def init_engine(self):
        """Initialize the query engine, based on configs"""
        pass
