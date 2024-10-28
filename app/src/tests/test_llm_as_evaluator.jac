import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py time;
import:py shutil;
import:py requests;
import:py subprocess;
import from helpers {get_item_by_label}

test app_running   {
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

# test run_query_engine   {
#     query_engine = subprocess.Popen(["jac", "run", "src/query_engine.jac"]);
#     time.sleep(10);
#     response = requests.get("http://localhost:8000");
#     assert response.status_code == 200;
#     assert response.json() == {"status": "ok"};
# }

# test llm_as_evaluator_wo_config   {
#     assert not app.exception;
#     app.session_state.admin_privileges = True;
#     app.run();
#     assert app.session_state.engine_status;
#     llm_as_evaluator_tab = get_item_by_label(app, "tab", "LLM as Evaluator");
#     assert llm_as_evaluator_tab.error;
# }

# test llm_as_evaluator_ab_testing   {
#     shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".human_eval_config");
#     :g: app ;
    
#     app = AppTest.from_file("app.py").run(timeout=20);
#     app.session_state.admin_privileges = True;
#     app.run();
#     assert not app.exception;
#     llm_as_evaluator_tab = get_item_by_label(app, "tab", "LLM as Evaluator");
#     assert not llm_as_evaluator_tab.error;
    
#     # TODO: Run the LLM as Evaluator
#     shutil.rmtree(".human_eval_config");
#     shutil.rmtree("runs");
# }

# test llm_as_evaluator_criteria   {
#     shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "criteria_config.zip"), ".human_eval_config");
#     :g: app ;
    
#     app = AppTest.from_file("app.py").run(timeout=20);
#     app.session_state.admin_privileges = True;
#     app.run();
#     assert not app.exception;
#     llm_as_evaluator_tab = get_item_by_label(app, "tab", "LLM as Evaluator");
#     assert not llm_as_evaluator_tab.error;
    
#     # TODO: Run the LLM as Evaluator
#     shutil.rmtree(".human_eval_config");
#     shutil.rmtree("runs");
# }
