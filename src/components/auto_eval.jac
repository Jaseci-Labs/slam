import:py streamlit as st;

can llm_as_evaluator;
can <>init;
can run_llm_as_evaluator(eval_model: str, all_questions: dict);
can process_inference_result(inference_result: dict);

can auto_eval {
    (gpt_evaluator, sim_scorer_tab,model_ranking) = st.tabs(["LLM as Evaluator", "Similarity Scorer", "Model Ranking"]);
    with sim_scorer_tab {emb_sim_scorer();}
    with model_ranking {model_win_percentage_table();}
    with gpt_evaluator {llm_as_evaluator();}
}