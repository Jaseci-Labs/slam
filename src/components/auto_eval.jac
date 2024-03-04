import:py streamlit as st;

import:jac from emb_sim_scorer, emb_sim_scorer;
import:jac from model_ranking, model_win_percentage_table;
import:jac from llm_as_evaluator, llm_as_evaluator;

can auto_eval {
    (gpt_evaluator, sim_scorer_tab,model_ranking) = st.tabs(["LLM as Evaluator", "Similarity Scorer", "Model Ranking"]);
    with sim_scorer_tab {emb_sim_scorer();}
    with model_ranking {model_win_percentage_table();}
    with gpt_evaluator {llm_as_evaluator();}
}