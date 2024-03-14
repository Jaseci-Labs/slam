import:py from fastapi, FastAPI;
import:py uvicorn;
import:py requests;
import:py subprocess;
import:py time;
import:py from langchain.globals, set_verbose, set_debug;


glob app = FastAPI();

with entry {
    set_verbose(True);
    set_debug(True);
}

obj QueryEngine {
    can init (provider_name: str = "openai", model_name: str = "gpt-4", temperature: float = 0.9) -> None;
    can init_engine(prompt_template:str) -> None; # Initialize the engine
    can load_chat_model() -> None; # Load a chat model
    can query(payload: dict) -> dict; # Process a query, return a response
    can __repr__ -> str;
}

glob engine = {"engine": None};
@app.get("/")
can status -> dict {return {"status": "ok"};}
@app.post("/load_engine")
can load_engine(config: dict) -> None; # Loads the query engine
@app.post("/query")
can query(payload:dict) -> dict; # Queries the query engine

with entry: __main__ {
    uvicorn.run(app, host="0.0.0.0", port=8000);
}

test run_server {
    query_engine = subprocess.Popen(["jac", "run", "src/query_engine.jac"]);
    ollama_server = subprocess.Popen(["ollama", "serve"]);
    time.sleep(10);
    response = requests.get("http://localhost:8000");
    assert response.status_code == 200;
    assert response.json() == {"status": "ok"};
    ollama_response = requests.get("http://localhost:11434");
    assert ollama_response.status_code == 200;
}

test load_engine_ollama {
    payload = {"config": {
        "provider_name": "ollama",
        "model_name": "orca-mini:3b",
        "temperature": 0.0,
        "prompt_template": "{something}"
    }};
    response = requests.post("http://localhost:8000/load_engine", json=payload);
    assert response.status_code == 200;
}

test query_ollama {
    payload = {"payload": {
        "something": "Hello"
    }};
    response = requests.post("http://localhost:8000/query", json=payload);
    assert response.status_code == 200;
    assert response.json()["full_prompt"] == "Hello";
    assert response.json()["response"];
}