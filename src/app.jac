include:jac components.utils;
include:jac components.theme;
include:jac components.generator;
include:jac components.setup;

can main {
    if "admin_privileges" not in st.session_state {
        st.session_state.admin_privileges = False;
    } 
    (human_eval_tab, admin_tab) = st.tabs(["Human Evaluation", "Admin Panel"]);
    with human_eval_tab {st.header("Human Evaluation");}
    with admin_tab {
        if not st.session_state.admin_privileges {
            with st.form(key='my_form') {
                username = st.text_input('Username');
                password = st.text_input('Password');
                if st.form_submit_button('Login') {
                    if username == "admin" and password == "admin" {
                        st.session_state.admin_privileges = True;
                    }
                }
            }
        } else {
            (dashboard_tab, generator_tab, evaluation_tab, setup_tab) = st.tabs(["Dashboard", "Response Generator", "GPT Evaluator", "Human Eval Setup"]);
            with dashboard_tab {
                st.header("Dashboard");
            }
            with generator_tab {
                generator();
            }
            with evaluation_tab {
                st.header("LLM Evaluator");
            }
            with setup_tab {
                setup();
            }
        }
    }
}