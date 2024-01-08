from rag_engine.query_engine import QueryEngine
from langchain.callbacks.base import BaseCallbackHandler
from langchain.callbacks import get_openai_callback
from typing import Any, Dict, List
from langchain.schema.messages import BaseMessage
from langchain.schema.output_parser import StrOutputParser
from langchain.prompts import ChatPromptTemplate


class ChatPromptHandler(BaseCallbackHandler):
    def __init__(self):
        super().__init__()
        self.prompt = ""

    def on_chat_model_start(
        self,
        serialized: Dict[str, Any],
        messages: List[List[BaseMessage]],
        **kwargs: Any,
    ) -> Any:
        self.prompt = messages


handler = ChatPromptHandler()


class General(QueryEngine):
    def __init__(self):
        self.model_name = "gpt-4"
        self.provider_name = "openai"

    def init_engine(self, prompt_template):
        self.chat_model = self.load_chat_model(
            provider_name=self.provider_name, model_name=self.model_name
        )
        prompt = ChatPromptTemplate.from_template(prompt_template)
        self.chain = prompt | self.chat_model | StrOutputParser()

    def query(self, payload):
        token_usage = None
        if self.provider_name == "openai":
            with get_openai_callback() as cb:
                response = self.chain.invoke(
                    payload,
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
                payload,
                config={"callbacks": [handler]},
            )

        return {
            "response": response,
            "full_prompt": handler.prompt[0][0].content,
            "token_usage": token_usage,
        }
