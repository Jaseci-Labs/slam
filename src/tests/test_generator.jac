import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py time;
import:py requests;
import:py subprocess;
import:jac from utils, get_item_by_label;

test app_running {
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test run_query_engine {
    :g: query_engine;
    query_engine = subprocess.Popen(["jac", "run", "src/query_engine.jac"]);
    time.sleep(10);
    response = requests.get("http://localhost:8000");
    assert response.status_code == 200;
    assert response.json() == {"status": "ok"};
}

test run_ollama_server {
    :g: ollama_server;
    ollama_server = subprocess.Popen(["ollama", "serve"]);
    time.sleep(10);
    response = requests.get("http://localhost:11434");
    assert response.status_code == 200;
}

test generator {
    assert not app.exception;
    app.session_state.admin_privileges = True;
    app.run();
    assert app.session_state.engine_status;
    
    generator_tab = get_item_by_label(app, "tab", "Response Generator");
    get_item_by_label(generator_tab, "multiselect", "Select Models").set_value(['ollama/orca-mini:3b']).run();
    get_item_by_label(generator_tab, "number_input", "Number of Samples").set_value(2).run();
    get_item_by_label(generator_tab, "number_input", "Temperature").set_value(0.0).run();
    get_item_by_label(generator_tab, "text_area", "Input Prompt Template").set_value("What is the meaning of {thing}?").run();
    generator_tab = get_item_by_label(app, "tab", "Response Generator");
    assert generator_tab.error[-1].value == "Make sure every field is filled properly";
    get_item_by_label(generator_tab, "text_input", "thing").set_value("life").run();
    generator_tab = get_item_by_label(app, "tab", "Response Generator");
    assert not generator_tab.error;
    get_item_by_label(generator_tab, "button", "Generate Responses").set_value(True).run();

    assert os.path.exists(os.path.join("runs", app.session_state.run_id, "orca-mini:3b.json"));
    assert os.path.exists(os.path.join("data", f"{app.session_state.run_id}_responses.json"));

    query_engine.terminate();
    ollama_server.terminate();
}

