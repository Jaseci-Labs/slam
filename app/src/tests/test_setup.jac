import:py json;
import:py os;
import:py shutil;
import from streamlit.testing.v1 {AppTest}

import from helpers {get_item_by_label}


test app_running   {
    :g: app ;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test setup_without_config   {
    app.session_state.admin_privileges = True;
    app.run();
    setup_tab = get_item_by_label(app, "tab", "Evaluation Setup");
    assert setup_tab.label == "Evaluation Setup";
    assert not app.exception;
}

test setup_humnan_eval_ab_testing   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "data.zip"), ".");
    app.run();
    setup_tab = get_item_by_label(app, "tab", "Evaluation Setup");
    get_item_by_label(setup_tab, "selectbox", "Select the Evaluation method").select("A/B Testing").run();
    get_item_by_label(setup_tab, "number_input", "Number of Evaluators").set_value(10);
    get_item_by_label(setup_tab, "number_input", "Number of questions per evaluator").set_value(2);
    get_item_by_label(setup_tab, "checkbox", "Show Captcha (Human Verification)").set_value(False);
    get_item_by_label(setup_tab, "checkbox", "Usecases are Evenly distributed among the evaluators").set_value(True).run();
    assert setup_tab.warning[-1].value == "Please upload at least one data source. or select one from the list if available.";

    datasource_selector = get_item_by_label(setup_tab, "multiselect", "Data sources (Usecases)");
    assert len(datasource_selector.options) == 1;
    datasource_selector.set_value(['city_name_responses.json']).run();

    setup_tab = get_item_by_label(app, "tab", "Evaluation Setup");
    assert setup_tab.text_input("city_name_responses.json_usecase_id");
    assert setup_tab.text_area("city_name_responses.json_prompt_disc");
    assert setup_tab.text_area("city_name_responses.json_prompt_simple_disc");
    setup_tab.text_area("city_name_responses.json_prompt_disc").set_value("This is a new prompt description");
    setup_tab.text_area("city_name_responses.json_prompt_simple_disc").set_value("This is a new simple prompt description");
    get_item_by_label(setup_tab, "button", "Create Evaluation Configuration").set_value(True).run();
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
    setup_tab = get_item_by_label(app, "tab", "Evaluation Setup");
    assert not setup_tab.exception;
    assert not setup_tab.error;
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("data");
    shutil.rmtree("runs");
    shutil.rmtree("results");
}
