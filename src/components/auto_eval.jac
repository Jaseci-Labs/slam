import:py streamlit as st;

import:jac from emb_sim_scorer, emb_sim_scorer;
import:jac from model_ranking, model_win_percentage_table;

can auto_eval {
    (gpt_evaluator, sim_scorer_tab,model_ranking) = st.tabs(["GPT Evaluator","Similarity Scorer","Model Ranking"]);
    with sim_scorer_tab {emb_sim_scorer();}
    with model_ranking {model_win_percentage_table();}
}