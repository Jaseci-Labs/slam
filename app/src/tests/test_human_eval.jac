import:py json;
import:py os;
import:py shutil;
import:py from streamlit.testing.v1, AppTest;

import:jac from helpers, get_item_by_label;


test app_running   {
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test human_eval_without_config {
    assert app.info[0].value == "Go to Admin Panel and configure the Human Evaluation.";
}

test human_eval_with_config   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    :g: app ;
    
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
    assert not app.error;
    shutil.rmtree(".human_eval_config");
}

test human_eval_config_ab_testing   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    :g: app ;
    
    app = AppTest.from_file("app.py").run(timeout=20);
    get_item_by_label(app, "text_input", "Worker ID").set_value("test_worker_id").run();
    assert os.path.exists(os.path.join(".human_eval_config", "worker_count.txt"));
    assert not app.exception;
    assert app.session_state.worker_id == "test_worker_id";
    
    # TODO: Perform one evaluation
    shutil.rmtree(".human_eval_config");
}

test human_eval_config_criteria   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "criteria_config.zip"), ".");
    :g: app ;
    
    app = AppTest.from_file("app.py").run(timeout=20);
    get_item_by_label(app, "text_input", "Worker ID").set_value("test_worker_id").run();
    assert os.path.exists(os.path.join(".human_eval_config", "worker_count.txt"));
    assert not app.exception;
    assert app.session_state.worker_id == "test_worker_id";
    
    # TODO: Perform one evaluation
    shutil.rmtree(".human_eval_config");
}
