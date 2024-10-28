import:py streamlit as st;
import from sentence_transformers {SentenceTransformer}

can generate_embeddings(anchor_responses_text: str, response_texts: list, embedder: str);
can calculate_similarity_score(anchor_embeddings: list, response_embeddings: list, scorer: str);
can display_results(basedir: str, heatmap_placeholder: st, selected_prompt: str=None);
can process_user_selections(selected_prompt: str=None);
can calculate_embedding_score(responses: list, anchor_reponses_id: dict, responses_dict: dict);
can embed_sentence(sentence: str, model: SentenceTransformer);
can compute_bleu_score(reference: list, candidate: list);
can semantic_bleu_score(anchor_responses_text: list, response_texts: list, model: SentenceTransformer, ngram_size: int=4, scaling_factor: float=1, bleu_weight: float=0.5);
can simple_bleu(reference: str, candidate: str, n_gram: int=4);

can emb_sim_scorer {
    if 'anchor_model' not in st.session_state {
        st.session_state['anchor_model'] = 'gpt-4';
    }
    if 'embedder' not in st.session_state {
        st.session_state['embedder'] = 'SBERT';
    }
    if 'scorer' not in st.session_state {
        st.session_state['scorer'] = 'cos_sim';
    }
    if st.session_state.get("current_hv_config", None) {
        button_clicked = st.session_state.get('button_clicked', False);
        model_list = st.session_state.active_list_of_models;
        if st.session_state['anchor_model'] not in model_list {
            st.session_state['anchor_model'] = model_list[0];
        }

        if st.session_state['anchor_model'] not in model_list {
            st.session_state['anchor_model'] = model_list[0];
        }
        
        (col1, col2, col3) = st.columns(3);
        anchor_model_selection = col1.selectbox("Select Anchor Model", options=model_list, key='anchor_model', index=model_list.index(st.session_state.get('anchor_model', model_list[0])));
        embedder_selection = col2.selectbox("Select Type of Embedder", options=['USE', 'USE_QA', 'SBERT'], key='embedder', index=['USE', 'USE_QA', 'SBERT', 'OPEN_AI_Embedder'].index(st.session_state.get('embedder', 'SBERT')));
        scorer_selection = col3.selectbox("Select Scorer", options=['cos_sim', 'sem_bleu'], key='scorer', index=['cos_sim', 'sem_bleu'].index(st.session_state.get('scorer', 'cos_sim')));

        if st.button('Calculate Embedding Scores') {
            try {
                with st.spinner('Calculating embedding scores... Please wait.'){
                    process_user_selections();
                    st.session_state['button_clicked'] = True;
                }
                st.success('Finished calculating embedding scores!');
            } except Exception as e{
                print(e);
                st.error('Error calculating embedding scores. Please try again.');
            } 
        }
        if button_clicked {
            st.session_state['button_clicked'] = False;
        }
    } else {
        st.error("Human Evaluation config was not found. Initialize a Human Evaluation first.");
    }
}
