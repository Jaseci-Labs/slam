import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;
import:jac from utils, get_item_by_label;

test app_running   {
    :g: app ;
    
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test setup_without_config   {
    app.session_state.admin_privileges = True;
    app.run();
    setup_tab = get_item_by_label(app, "tab", "Human Eval Setup");
    assert setup_tab.label == "Human Eval Setup";
    assert not app.exception;
}

test setup_humnan_eval_ab_testing   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "data.zip"), ".");
    app.run();
    setup_tab = get_item_by_label(app, "tab", "Human Eval Setup");
    get_item_by_label(setup_tab, "selectbox", "Select the human evaluation method").select("A/B Testing").run();
    get_item_by_label(setup_tab, "number_input", "Number of workers").set_value(100);
    get_item_by_label(setup_tab, "number_input", "Number of questions per worker").set_value(3);
    get_item_by_label(setup_tab, "checkbox", "Show Captcha").set_value(False);
    get_item_by_label(setup_tab, "checkbox", "Usecases are Evenly distributed among the workers").set_value(True).run();
    assert setup_tab.warning[0].value == "Please upload at least one data source. or select one from the list if available.";
    datasource_selector = get_item_by_label(setup_tab, "multiselect", "Data sources (Usecases)");
    assert len(datasource_selector.options) == 5;
    datasource_selector.set_value(['peptalk_responses.json', 'first_task_responses.json', 'recommendation_responses.json']).run();
    setup_tab = get_item_by_label(app, "tab", "Human Eval Setup");
    assert not setup_tab.warning;
    assert setup_tab.text_input("recommendation_responses.json_usecase_id");
    assert setup_tab.text_area("recommendation_responses.json_prompt_disc");
    assert setup_tab.text_area("recommendation_responses.json_prompt_simple_disc");
    setup_tab.text_area("recommendation_responses.json_prompt_disc").set_value("This is a new prompt description");
    setup_tab.text_area("recommendation_responses.json_prompt_simple_disc").set_value("This is a new simple prompt description");
    setup_tab.get("button")[-1].set_value(True).run();
    assert not app.exception;
    assert os.path.exists(".human_eval_config");
    assert os.path.exists(os.path.join(".human_eval_config", "config.json"));
    assert os.path.exists(os.path.join(".human_eval_config", "distribution.json"));
    assert os.path.exists(os.path.join(".human_eval_config", "models_responses.json"));
    assert os.path.exists(os.path.join(".human_eval_config", "prompt_info.json"));
    assert os.path.exists(os.path.join(".human_eval_config", "responses.json"));
    assert os.path.exists(os.path.join(".human_eval_config", "unique_question_pairs.json"));
    with open(os.path.join(".human_eval_config", "prompt_info.json"), "r") as f {
        prompt_info = json.load(f);
    }
    assert prompt_info[-1]["prompt_simple_disc"] == "This is a new simple prompt description";
    assert prompt_info[-1]["prompt_disc"] == "This is a new prompt description";
}

test setup_with_existing_config   {
    :g: app ;
    
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    setup_tab = get_item_by_label(app, "tab", "Human Eval Setup");
    assert not setup_tab.exception;
    assert not setup_tab.error;
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("data");
}
