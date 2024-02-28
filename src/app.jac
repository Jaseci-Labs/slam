import:py streamlit as st;

import:jac from components.utils, login;
import:jac from components.generator, generator;
import:jac from components.setup, setup;
import:jac from components.human_eval, human_eval;
import:jac from components.dashboard, dashboard;
import:jac from components.llm_eval, evaluator;
import:jac from components.about, about;
import:jac from components.theme, footer;
import:jac from components.emb_sim_scorer, ui_components;

can main {
    if "admin_privileges" not in st.session_state {st.session_state.admin_privileges = False;} 
    # (human_eval_tab, admin_tab, about_tab) = st.tabs(["Human Evaluation", "Admin Panel", "About"]);
    (human_eval_tab, admin_tab) = st.tabs(["Human Evaluation", "Admin Panel"]);
    with human_eval_tab {human_eval();}
    with admin_tab {
        if not st.session_state.admin_privileges {login();}
        else {
            (dashboard_tab, generator_tab, evaluation_tab, setup_tab) = st.tabs(["Dashboard",
                                        "Response Generator", "Auto Evaluator", "Human Eval Setup"]);
            with dashboard_tab {dashboard();}
            with generator_tab {generator();}
            with evaluation_tab {
                (gpt_evaluator, sim_scorer_tab) = st.tabs(["GPT Evaluator","Similarity Scorer"]);
                with gpt_evaluator {evaluator();}
                with sim_scorer_tab {ui_components();}
                
            }
            with setup_tab {setup();}
        }
    }
    # with about_tab {about();}
    footer();
}