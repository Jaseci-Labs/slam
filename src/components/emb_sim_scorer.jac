import:py streamlit as st;
import:py from sentence_transformers, SentenceTransformer;

can generate_embeddings(anchor_responses_text:str, response_texts:list, embedder:str);
can calculate_similarity_score (anchor_embeddings:list, response_embeddings:list, scorer:str);
can display_results(basedir:str, heatmap_placeholder:st,selected_prompt:str=None);
can process_user_selections(selected_prompt:str=None);
can calculate_embedding_score(responses: list, anchor_reponses_id: dict, responses_dict: dict);
can embed_sentence (sentence:str, model:SentenceTransformer);
can compute_bleu_score (reference:list, candidate:list);
can semantic_bleu_score (anchor_responses_text:list, response_texts:list, model: SentenceTransformer , ngram_size:int=4, scaling_factor:float=1, bleu_weight:float=0.5);

glob ANCHOR_MODEL_KEY = 'anchor_model';
glob EMBEDDER_KEY = 'embedder';
glob SCORER_KEY = 'scorer';

can emb_sim_scorer {
    if ANCHOR_MODEL_KEY not in st.session_state{
        st.session_state[ANCHOR_MODEL_KEY] = 'gpt-4';
    }
    if EMBEDDER_KEY not in st.session_state{
        st.session_state[EMBEDDER_KEY] = 'SBERT';
    }
    if SCORER_KEY not in st.session_state{
        st.session_state[SCORER_KEY] = 'cos_sim';
    }

    if st.session_state.get("current_hv_config", None) {
        if 'button_clicked' not in st.session_state{st.session_state.button_clicked = False;} 
        if st.session_state.button_clicked{
            if "selected_prompt" in st.session_state{
                process_user_selections(st.session_state["selected_prompt"]);
            }
            # st.session_state.button_clicked = False;
        }
        model_list=st.session_state.active_list_of_models;
        (col1, col2, col3) = st.columns(3);
        with col1{
            anchor_model_selection = st.selectbox(
                "Select Anchor Model",
                options=model_list,
                key=ANCHOR_MODEL_KEY,index=model_list.index(st.session_state[ANCHOR_MODEL_KEY])
            );
        }
        with col2{
            embedder_selection = st.selectbox(
                "Select Type of Embedder",
                options=['USE', 'USE_QA', 'SBERT'],
                key=EMBEDDER_KEY, index=['USE', 'USE_QA', 'SBERT', 'OPEN_AI_Embedder'].index(st.session_state[EMBEDDER_KEY])
            );
        }
        with col3{
            scorer_selection = st.selectbox(
                "Select Scorer",
                options=['cos_sim', 'sem_bleu'],
                key=SCORER_KEY, index=['cos_sim', 'sem_bleu'].index(st.session_state[SCORER_KEY])
            );
        }
        
        if st.button('Calculate Embedding Scores'){
           st.session_state.button_clicked = True;
           process_user_selections();
            
        }
    } else {
        st.error("Human Evaluation config was not found. Initialize a Human Evaluation first.");
    }
}