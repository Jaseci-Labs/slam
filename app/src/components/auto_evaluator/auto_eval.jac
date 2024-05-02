'''Auto Evaluator.'''
import:py streamlit as st;
import:jac from emb_sim_scorer, emb_sim_scorer;
import:jac from llm_as_evaluator, llm_as_evaluator;

'''Auto Evaluator Window.'''
can auto_eval {
    (gpt_evaluator, sim_scorer_tab) = st.tabs(["LLM as an Evaluator", "Similarity Scorer"]);
    with sim_scorer_tab {
        emb_sim_scorer();
    }
    with gpt_evaluator {
        llm_as_evaluator();
    }
}
