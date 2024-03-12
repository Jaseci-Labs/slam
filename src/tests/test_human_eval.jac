import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;
import:jac from utils, get_item_by_label;

glob app = AppTest.from_file("app.py").run(timeout=20);

test app_running {
    :g: app;
    assert not app.exception;
}

test human_eval_without_config {
    assert app.error[0].value == "No human eval config found.";
}

test human_eval_with_config {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "config.zip"), ".human_eval_config");
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
    assert not app.error;
    shutil.rmtree(".human_eval_config");
}

test human_eval_config_ab_testing {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "config.zip"), ".human_eval_config");
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    get_item_by_label(app, "text_input", "Worker ID").set_value("test_worker_id").run();

    assert os.path.exists(os.path.join(".human_eval_config", "worker_count.txt"));
    shutil.rmtree(".human_eval_config");
}