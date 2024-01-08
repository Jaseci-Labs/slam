import:py from jaseci.jsorc.live_actions, jaseci_action;
import:py from langchain.globals, set_verbose, set_debug;

include:jac query_engine_impl;

with entry {
    set_verbose(True);
    set_debug(True);
}

obj QueryEngine {
    can <init> (provider_name: str = "openai", model_name: str = "gpt-4") -> None;
    can init_engine(prompt_template:str) -> None; # Initialize the engine
    can load_chat_model() -> None; # Load a chat model
    can query(payload: dict) -> dict; # Process a query, return a response
}

glob engine = None;

@jaseci_action(act_group=["query_engine"], allow_remote=True)
can load_engine(config: dict) -> None; # Loads the query engine
@jaseci_action(act_group=["query_engine"], allow_remote=True)
can query(payload:dict) -> dict; # Queries the query engine