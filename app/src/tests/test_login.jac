import:py from streamlit.testing.v1, AppTest;
import:py os;

import:jac from helpers, get_item_by_label;

test app_running   {
    :g: app;
    os.environ["SLAM_ADMIN_USERNAME"] = "username";
    os.environ["SLAM_ADMIN_PASSWORD"] = "password";
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test login   {
    admin_tab = get_item_by_label(app, "tab", "Admin Panel");
    admin_tab.text_input("username").input("username");
    admin_tab.text_input("password").input("wrong_password");
    get_item_by_label(admin_tab, "button", "Login").set_value(True).run();
    assert app.get("error")[0].value == "Invalid username or password";
    assert not app.session_state.admin_privileges;
    admin_tab.text_input("username").input("username");
    admin_tab.text_input("password").input("password");
    get_item_by_label(admin_tab, "button", "Login").set_value(True).run();
    assert app.session_state.admin_privileges;
}
