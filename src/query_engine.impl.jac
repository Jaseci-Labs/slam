import:py from langchain.chat_models, ChatOpenAI, ChatOllama;
import:py from langchain.llms, LlamaCpp;
import:py from langchain.prompts, ChatPromptTemplate;
import:py from langchain.schema.output_parser, StrOutputParser;
import:py from langchain.callbacks, get_openai_callback;
import:py from langchain.callbacks.base, BaseCallbackHandler;
import:py from jaseci.utils.utils, logger;
import:py ollama;

obj ChatPromptHandler:BaseCallbackHandler: {
    can init;
    can on_chat_model_start(serialized: dict, messages: list, **kwargs: dict) -> None;
}

:obj:ChatPromptHandler:can:init {
    super.init();
    self.prompt = "";
}

:obj:ChatPromptHandler:can:on_chat_model_start(serialized: dict, messages: list, **kwargs: dict) -> None {
    self.prompt = messages;
}

:obj:QueryEngine:can:init(provider_name: str = "openai", model_name: str = "gpt-4", temperature: float = 0.9) {
    self.provider_name = provider_name;
    self.model_name = model_name;
    self.temperature = temperature;
    self.handler = ChatPromptHandler();
}

:obj:QueryEngine:can:init_engine(prompt_template:str) {
    self.chat_model = self.load_chat_model();
    prompt = ChatPromptTemplate.from_template(prompt_template);
    self.chain = prompt | self.chat_model | StrOutputParser();
}

:obj:QueryEngine:can:load_chat_model {
    if self.provider_name == "openai" {
        return ChatOpenAI(model_name = self.model_name, temperature = self.temperature);
    } elif self.provider_name == "ollama" {
        if self.model_name not in ollama.list()['models'] {ollama.pull(self.model_name);}
        return ChatOllama(model = self.model_name, temperature = self.temperature);
    } elif self.provider_name == "llama.cpp" {
        return LlamaCpp(model = self.model_name);
    } else {
        raise ValueError(f"Invalid chat model provider name: {self.provider_name}");
    }
}

:obj:QueryEngine:can:query(payload: dict) -> dict {
    token_usage = None;
    if self.provider_name == "openai" {
        with get_openai_callback() as cb {
            response = self.chain.invoke(payload, config={"callbacks": [self.handler]});
        }
        token_usage = {
            "total_tokens": cb.total_tokens,
            "completion_tokens": cb.completion_tokens,
            "prompt_tokens": cb.prompt_tokens,
            "total_cost": cb.total_cost
        };
    } else {
        response = self.chain.invoke(payload, config={"callbacks": [self.handler]});
    }
    return {
        "response": response,
        "full_prompt": self.handler.prompt[0][0].content,
        "token_usage": token_usage
    };
}

:obj:QueryEngine:can:__repr__ -> str {
    return f"QueryEngine(provider_name={self.provider_name}, model_name={self.model_name})";
}

:can:load_engine(config: dict) -> None {
    provider_name = config["provider_name"];
    model_name = config["model_name"];
    temperature = config["temperature"];
    logger.info(f"Loading query engine with {provider_name}'s {model_name} model");

    engine["engine"] = QueryEngine(provider_name, model_name, temperature);
    engine["engine"].init_engine(config["prompt_template"]);
}

:can:query(payload:dict) -> dict {
    logger.info(f"Querying engine with payload: {payload}");
    if engine["engine"] is None{
        raise Exception("Query engine not loaded");
    }
    return engine["engine"].query(payload);
}