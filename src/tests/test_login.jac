import:py from streamlit.testing.v1, AppTest;
import:py os;

glob app = AppTest.from_file("app.py").run(timeout=20);

test app_running {
    :g: app;
    assert not app.exception;
}

test login {
    :g: app;
    admin_tab = app.get("tab")[1];
    assert admin_tab.label == "Admin Panel";

    admin_tab.text_input("username").input("admin");
    admin_tab.text_input("password").input("admin");
    admin_tab.get("button")[0].set_value(True).run();
    assert app.get("error")[1].value == "Invalid username or password";
    assert not app.session_state.admin_privileges;

    os.environ["SLAM_ADMIN_USERNAME"] = "username";
    os.environ["SLAM_ADMIN_PASSWORD"] = "password";

    admin_tab.text_input("username").input("username");
    admin_tab.text_input("password").input("password");
    admin_tab.get("button")[0].set_value(True).run();
    assert app.session_state.admin_privileges;
}