from rag_engine.query_engine import QueryEngine
from graph2doc.graph2doc import Graph2Doc
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
from langchain.callbacks.base import BaseCallbackHandler
from langchain.callbacks import get_openai_callback
from typing import Any, Dict, List
from langchain.schema.messages import BaseMessage
from rag_engine.engines.myca_prompt_templates import (
    MYCA_GENERIC_PROMPT_TEMPLATE,
    MYCA_PEPTALK_PROMPT_TEMPLATE,
    MYCA_NEW_USER_PEPTALK_PROMPT_TEMPLATE,
)


class ChatPromptHandler(BaseCallbackHandler):
    def __init__(self):
        super().__init__()
        self.prompt = ""

    def on_chat_model_start(
        self,
        serialized: Dict[str, Any],
        messages: List[List[BaseMessage]],
        **kwargs: Any
    ) -> Any:
        self.prompt = messages


handler = ChatPromptHandler()


class Myca(QueryEngine):
    """Custom query engine for Myca"""

    config_vars = ["feature_name", "graph2doc_method", "provider_name", "model_name"]

    def __init__(self):
        self.feature_name = "myca_new_user_peptalk"
        self.graph2doc_method = "custom_myca_new_user_peptalk"
        self.provider_name = "openai"
        self.model_name = "gpt-4"

    def init_engine(self):
        # Fetch prompt
        if self.feature_name == "myca_new_user_peptalk":
            prompt_template = MYCA_NEW_USER_PEPTALK_PROMPT_TEMPLATE
        elif self.feature_name == "myca_peptalk":
            prompt_template = MYCA_PEPTALK_PROMPT_TEMPLATE
        else:
            prompt_template = MYCA_GENERIC_PROMPT_TEMPLATE

        # Init graph2doc module
        self.graph2doc = Graph2Doc.create(method=self.graph2doc_method)

        # Init the chat model
        self.chat_model = self.load_chat_model(
            provider_name=self.provider_name, model_name=self.model_name
        )

        # Make the prompt
        prompt = ChatPromptTemplate.from_template(prompt_template)

        # Create the chain
        self.chain = prompt | self.chat_model | StrOutputParser()

    def query(self, payload):
        # Convert currently returns  documents and doc ids
        context_str, _ = self.graph2doc.convert(payload["context"])
        context_str = "\n".join(context_str)
        
        token_usage = None
        if self.provider_name == "openai":
            with get_openai_callback() as cb:
                response = self.chain.invoke(
                    {"context_str": context_str, "query": payload["query"]},
                    config={"callbacks": [handler]},
                )
            token_usage = {
                "total_tokens": cb.total_tokens,
                "completion_tokens": cb.completion_tokens,
                "prompt_tokens": cb.prompt_tokens,
                "total_cost": cb.total_cost,
            }
        else:
            response = self.chain.invoke(
                {"context_str": context_str, "query": payload["query"]},
                config={"callbacks": [handler]},
            )

        return {"response": response, "full_prompt": handler.prompt[0][0].content, "token_usage": token_usage}
