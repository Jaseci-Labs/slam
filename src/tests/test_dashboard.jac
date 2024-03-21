import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;
import:py time;
import:jac from utils, get_item_by_label, get_item_by_label_recursive;
import:py from pathlib, Path;

glob app = AppTest.from_file("app.py").run(timeout=20);


test app_running {
    :g: app;
    assert not app.exception;
    human_eval = Path(os.path.abspath(".human_eval_config"));
    results = Path(os.path.abspath("results"));
    if human_eval.exists(){shutil.rmtree(human_eval);}
    if results.exists(){shutil.rmtree(results);}
}

# test login {
#     :g: app;
#     admin_tab = app.get("tab")[1];
#     assert admin_tab.label == "Admin Panel";

#     admin_tab.text_input("username").input("admin");
#     admin_tab.text_input("password").input("username");
#     admin_tab.get("button")[0].set_value(True).run(timeout=6);
#     assert app.get("error")[1].value == "Invalid username or password";
#     assert not app.session_state.admin_privileges;

#     os.environ["SLAM_ADMIN_USERNAME"] = "admin";
#     os.environ["SLAM_ADMIN_PASSWORD"] = "admin";

#     admin_tab.text_input("username").input("admin");
#     admin_tab.text_input("password").input("admin");
#     admin_tab.get("button")[0].set_value(True).run(timeout=6);
#     assert app.session_state.admin_privileges;
# }

# # Test Initialization and Configuration Loading
# test test_initialization_and_config_loading {
#     :g: app;
#     app.session_state.admin_privileges = True;
#     assert "current_hv_config not found in session_state.", app.session_state.current_hv_config;
#     assert not app.exception;
#     assert not os.path.exists(os.path.join(".human_eval_config", "config.json"));
#     shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "config.zip"), ".");
#     app = AppTest.from_file("app.py").run(timeout=20);
#     app.session_state.admin_privileges = True;
#     app.run();
#     assert app.session_state.current_hv_config;
#     shutil.rmtree(".human_eval_config");
# }

# Test Upload Functionality
# test test_upload_functionality {
#     dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
#     print(f"dashboard_tab tab: {dashboard_tab}");
#     upload_tab = get_item_by_label(app, "Upload");
#     print(f"upload tab: {upload_tab}");
#     file_uploader = get_item_by_label(upload_tab, "file_uploader", "Upload the Output File");
#     print(f"file_uploader: {file_uploader}");
#     file_uploader.upload("data.zip");
#     upload_button = get_item_by_label(upload_tab, "form_submit_button", "Upload & Unzip");
#     print(f"upload button: {upload_button}");
#     upload_button.run();
    
#     # assert os.path.exists("results");
#     # assert os.path.exists(".human_eval_config");
#     # assert os.path.exists("data");

# }

# Test Upload Functionality
test test_upload_functionality {

    :g: app;
    admin_tab = get_item_by_label(app, "tab", "Admin Panel");
    app.session_state.admin_privileges = True;
    print(admin_tab);
    os.environ["SLAM_ADMIN_USERNAME"] = "admin";
    os.environ["SLAM_ADMIN_PASSWORD"] = "admin";

    admin_tab.text_input("username").input("admin");
    admin_tab.text_input("password").input("admin");
    admin_tab.get("button")[0].set_value(True).run(timeout=6);
    assert app.session_state.admin_privileges;

    dashboard_tab = get_item_by_label(app, "tab", "Dashboard");
    print(f"dashboard_tab tab: {dashboard_tab}");
    # print(f"dashboard_tab error: {dashboard_tab.error[0].value}");
    # shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "config.zip"), ".");
    # shutil.unpack_archive(os.path.join(os.path.dirname(__file__),"fixtures", "results.zip"), ".");
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    # dashboard_tab.run();
    # print(dashboard_tab.button[0].click().run());
    refresh_button=get_item_by_label(dashboard_tab, "button", "Refresh").set_value(True);
    print(dashboard_tab);
    print(refresh_button.run(timeout=40));
    dashboard_tab= get_item_by_label(app, "tab", "Dashboard");
    # time.sleep(10);
    # dashboard_tab.run(timeout=10);
    print(f"dashboard_tab tab: {dashboard_tab}");
    # Assuming 'Upload' is either a direct child of the dashboard or identifiable globally
    # upload_tab = get_item_by_label_recursive(app, "expandable","Upload");
    # print(f"upload tab: {upload_tab}");
    
    # Locate the file uploader within the Upload tab
    # This assumes 'Upload the Output File' is a label or key identifying the uploader
    # file_uploader = get_item_by_label(dashboard_tab, "file_uploader", "Upload the Output File");
    # print(f"file_uploader: {file_uploader.label}");
    
    # # Simulate uploading a file named 'data.zip'
    # file_uploader.set_value("data.zip").run();
    
    # # Find the 'Upload & Unzip' button within the upload tab/form and click/run it
    # upload_button = get_item_by_label(upload_tab, "form_submit_button", "Upload & Unzip");
    # print(f"upload button: {upload_button}");
    # upload_button.run();
    
    # The commented assertions below are placeholders for validation checks you might want to perform
    # to ensure that the upload and any subsequent processing have been successful.
    # You'll need to uncomment and possibly adjust these lines based on your application's file structure
    # and what it does with the uploaded file.

    # assert os.path.exists("results"), "The 'results' directory does not exist after upload."
    # assert os.path.exists(".human_eval_config"), "The '.human_eval_config' file does not exist after upload."
    # assert os.path.exists("data"), "The 'data' directory does not exist after upload."
}

# # Test Status Indicators
# test test_status_indicators {
#    pass
# }
# # Test Chart Type Selection and Rendering
# test test_chart_type_selection_and_rendering {
#     pass
# }

# # Test Refresh Button
# test test_refresh_button{
#     pass
# }

# # Test Distribution Generation
# test test_distribution_generation{
#     pass
# }

# # Test Histogram Generation
# test test_histogram_generation{
#     pass
# }

# # Test Heat Map Generation
# test test_heat_map_generation{
#     pass
# }

# # Test Stacked Bar Chart Generation
# test test_stacked_bar_chart_generation{
#     pass
# }

# # Test Error Handling
# test test_error_handling{
#     pass
# }

# # Test Dynamic UI Updates
# test test_dynamic_ui_updates{
#     pass
# }
