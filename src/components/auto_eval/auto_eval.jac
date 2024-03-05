import:py streamlit as st;

import:jac from emb_sim_scorer, emb_sim_scorer;
import:jac from llm_as_evaluator, llm_as_evaluator;

can auto_eval {
    (gpt_evaluator, sim_scorer_tab) = st.tabs(["LLM as Evaluator", "Similarity Scorer"]);
    with sim_scorer_tab {emb_sim_scorer();}
    with gpt_evaluator {llm_as_evaluator();}
}