import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;

glob app = AppTest.from_file("app.py").run(timeout=20);

test app_running {
    :g: app;
    assert not app.exception;
}

test setup_without_config {
    app.session_state.admin_privileges = True;
    app.run();
    setup_tab = app.get("tab")[-2];
    assert setup_tab.label == "Human Eval Setup";
    assert not app.exception;
}

test setup_humnan_eval_ab_testing {
    setup_tab = app.get("tab")[-2];
    setup_tab.get("selectbox")[0].select("A/B Testing").run(); #Setting the Human Eval Method
    setup_tab.get("number_input")[1].set_value(100); # Setting the number of workers
    setup_tab.get("number_input")[2].set_value(3); # Setting the number of questions per worker
    setup_tab.get("checkbox")[0].set_value(False); # Disabling the Captcha Verification
    setup_tab.get("checkbox")[1].set_value(True); # Enabling the Even Distribution

    setup_tab.get("button")[0].set_value(True).run();
    assert setup_tab.warning[0].value == "Please upload at least one data source. or select one from the list if available.";
    # assert not len(setup_tab.get("multiselect")[0].options);

    # Unzip the data folder
    setup_tab.run();
    assert len(setup_tab.get("multiselect")[0].options) == 5;
    setup_tab.get("multiselect")[0].set_value(['peptalk_responses.json', 'first_task_responses.json', 'recommendation_responses.json']).run();
    assert app.text_input("recommendation_responses.json_usecase_id");
    assert app.text_area("recommendation_responses.json_prompt_disc");
    assert app.text_area("recommendation_responses.json_prompt_simple_disc").run();
    
    app.text_area("recommendation_responses.json_prompt_disc").set_value("This is a new prompt description");
    app.text_area("recommendation_responses.json_prompt_simple_disc").set_value("This is a new simple prompt description");
    app.get("button")[-1].set_value(True).run();

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
    shutil.rmtree(".human_eval_config");
}

test setup_with_existing_config {
    # extract the config.zip to .human_eval_config
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "config.zip"), ".human_eval_config");
    :g: app;
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    setup_tab = [tab for tab in app.get("tab") if tab.label == "Human Eval Setup"][0];
    assert not setup_tab.exception;
    assert not setup_tab.error;
    shutil.rmtree(".human_eval_config");
}