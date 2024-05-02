import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;
import:py time;
import:jac from utils, get_item_by_label;
import:py from pathlib, Path;

glob app = AppTest.from_file("app.py").run(timeout=20);

test app_running   {
    :g: app ;
    
    assert not app.exception;
    human_eval = Path(os.path.abspath(".human_eval_config"));
    results = Path(os.path.abspath("results"));
    if human_eval.exists() {
        shutil.rmtree(human_eval);
    }
    if results.exists() {
        shutil.rmtree(results);
    }
}

test test_initialization_and_config_loading   {
    """Tests initialization and configuration loading.""";
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    assert ("current_hv_config not found in session_state.") , app.session_state.current_hv_config;
    assert not app.exception;
    assert not os.path.exists(os.path.join(".human_eval_config", "config.json"));
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    assert app.session_state.current_hv_config;
    shutil.rmtree(".human_eval_config");
}

test test_error_validation   {
    """Tests if appropriate error messages are displayed for missing configuration and results.""";
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    
    # Assert error messages for missing configuration and results
    assert (dashboard_tab.error[0].value == "Human Evaluation config was not found. Initialize a Human Evaluation first.");
    assert (dashboard_tab.error[1].value == "Results were not found. Initialize a Human Evaluation first. If Initiated already, wait until the results are ready.");
}

test test_upload_functionality   {
    """Tests basic upload functionality (placeholder for specific assertions).""";
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "results.zip"), ".");
    app = AppTest.from_file("app.py").run(timeout=20);
    admin_tab = get_item_by_label(app, "tab", "Admin Panel");
    os.environ["SLAM_ADMIN_USERNAME"] = "admin";
    os.environ["SLAM_ADMIN_PASSWORD"] = "admin";
    admin_tab.text_input("username").input("admin");
    admin_tab.text_input("password").input("admin");
    admin_tab.get("button")[0].set_value(True).run(timeout=6);
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    dashboard_tab.button[0].click().run();
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    selectbox = (get_item_by_label(app, "selectbox", "Select a chart type:").set_value("Stacked Bar Chart").run());

    assert len(selectbox.session_state.hv_results_files) > 0;
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("results");
}

test test_chart_type_selection   {
    """Tests basic upload functionality (placeholder for specific assertions).""";
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "results.zip"), ".");
    app = AppTest.from_file("app.py").run(timeout=20);
    admin_tab = get_item_by_label(app, "tab", "Admin Panel");
    os.environ["SLAM_ADMIN_USERNAME"] = "admin";
    os.environ["SLAM_ADMIN_PASSWORD"] = "admin";
    admin_tab.text_input("username").input("admin");
    admin_tab.text_input("password").input("admin");
    admin_tab.get("button")[0].set_value(True).run(timeout=6);
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    dashboard_tab.button[0].click().run();
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    selectbox = (get_item_by_label(dashboard_tab, "selectbox", "Select a chart type:").set_value("Stacked Bar Chart").run());
    assert get_item_by_label(selectbox, "selectbox", "Select a chart type:").value == "Stacked Bar Chart";
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("results");
}

test test_refresh_button   {
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    assert dashboard_tab.error;
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "results.zip"), ".");
    app = AppTest.from_file("app.py").run(timeout=20);
    admin_tab = get_item_by_label(app, "tab", "Admin Panel");
    os.environ["SLAM_ADMIN_USERNAME"] = "admin";
    os.environ["SLAM_ADMIN_PASSWORD"] = "admin";
    admin_tab.text_input("username").input("admin");
    admin_tab.text_input("password").input("admin");
    admin_tab.get("button")[0].set_value(True).run(timeout=6);
    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    dashboard_tab.button[0].click().run();
    assert not dashboard_tab.error;
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("results");
}
