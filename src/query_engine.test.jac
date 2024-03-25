import:py subprocess;
import:py time;
import:py requests;

test run_query_engine   {
    :g: query_engine ;
    
    query_engine = subprocess.Popen(["jac", "run", "src/query_engine.jac"]);
    time.sleep(10);
    response = requests.get("http://localhost:8000");
    assert response.status_code == 200;
    assert response.json() == {"status":"ok" };
}

test run_ollama_server   {
    :g: ollama_server ;
    
    ollama_server = subprocess.Popen(["ollama", "serve"]);
    time.sleep(10);
    response = requests.get("http://localhost:11434");
    assert response.status_code == 200;
}

test load_engine_ollama   {
    payload = {"config":{"provider_name":"ollama", "model_name":"orca-mini:3b", "temperature":0.0, "prompt_template":"{something}" } };
    response = requests.post("http://localhost:8000/load_engine", json=payload);
    assert response.status_code == 200;
}

test query_ollama   {
    payload = {"payload":{"something":"Hello" } };
    response = requests.post("http://localhost:8000/query", json=payload);
    assert response.status_code == 200;
    assert response.json()["full_prompt"] == "Hello";
    assert response.json()["response"];
    ollama_server.kill();
    query_engine.kill();
}
