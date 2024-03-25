import:py from fastapi, FastAPI;
import:py uvicorn;
import:py from langchain.globals, set_verbose, set_debug;

glob app = FastAPI();

with entry {
    set_verbose(True);
    set_debug(True);
}

obj QueryEngine {
    can init(provider_name: str="openai", model_name: str="gpt-4", temperature: float=0.9) -> None;
    can init_engine(prompt_template: str) -> None;# Initialize the engine
    can load_chat_model() -> None;# Load a chat model
    can query(payload: dict) -> dict;# Process a query, return a response
    can __repr__ -> str;
}

glob engine = {"engine":None };

@app.get("/")
can status -> dict {
    return {"status":"ok" };
}

@app.post("/load_engine")
can load_engine(config: dict) -> None;# Loads the query engine

@app.post("/query")
can query(payload: dict) -> dict;# Queries the query engine

with entry:__main__ {
    uvicorn.run(app, host="0.0.0.0", port=8000);
}
