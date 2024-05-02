import:py os;
import:py streamlit as st;


'''Login Screen.'''
can login {
    (logo_col, login_col) = st.columns(2);
    with logo_col {
        st.header("Welcome to SLaM Tool!");
        st.info("SLaM Tool allows you to run human evaluations and llm evaluations on various propietary and open-source language models.");
        st.info("Please login to access the dashboard, evaluation and other features.");
    }
    with login_col {
        with st.form(key='my_form') {
            username = st.text_input('Username', key="username");
            password = st.text_input('Password', <>type='password', key="password");
            if st.form_submit_button('Login') {
                try  {
                    if username == os.environ.get("SLAM_ADMIN_USERNAME")
                        and password == os.environ.get("SLAM_ADMIN_PASSWORD") {
                        st.session_state.admin_privileges = True;
                        st.rerun();
                    } else {
                        st.error("Invalid username or password");
                    }
                } except Exception as e  {
                    st.error("Admin Account not configured. Please contact the administrator.");
                }
            }
        }
    }
}