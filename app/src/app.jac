'''SLaM Tool.'''
import:py streamlit as st;
import from components.about {about}
import from components.auto_evaluator.auto_eval {auto_eval}
import from components.dashboard.dashboard {dashboard}
import from components.generator.generator {generator}
import from components.human_eval.human_eval {human_eval}
import from components.login {login}
import from components.setup.setup {setup}
import from components.theme {footer}

'''Main function for the SLaM Tool.'''
can main {
    if "admin_privileges" not in st.session_state {
        st.session_state.admin_privileges = False;
    }
    (human_eval_tab, admin_tab) = st.tabs(["Human Evaluation", "Admin Panel"]);
    with human_eval_tab {
        human_eval();
    }
    with admin_tab {
        if not st.session_state.admin_privileges {
            login();
        } else {
            (dashboard_tab, generator_tab, setup_tab, evaluation_tab, about_tab) = st.tabs(["Dashboard", "Response Generator", "Evaluation Setup", "Auto Evaluator", "About"]);
            with dashboard_tab {
                dashboard();
            }
            with generator_tab {
                generator();
            }
            with setup_tab {
                setup();
            }
            with evaluation_tab {
                auto_eval();
            }
            with about_tab {
                about();
            }
        }
    }
    footer();
}
