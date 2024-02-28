import:py streamlit as st;
import:py os;
import:py json;
import:py time;
import:py from sklearn.metrics.pairwise, cosine_similarity;
import:py numpy as np;
import:jac from dashboard, heat_map;
import:py from pathlib, Path;
import:py from sentence_transformers, SentenceTransformer;
import:py from nltk.tokenize, word_tokenize;
import:py from nltk.translate.bleu_score, sentence_bleu;
import:py from nltk.translate.bleu_score, SmoothingFunction;
import:py from torch, tensor;
import:py from nltk, ngrams;

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

can ui_components {
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
                options=['USE', 'USE_QA', 'SBERT', 'OPEN_AI_Embedder'],
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


:can:generate_embeddings (anchor_responses_text:list, response_texts:list, embedder:str) {
    anchor_embeddings = [];
    response_embeddings = [];

    if embedder == "SBERT" {
        model = SentenceTransformer('all-MiniLM-L6-v2');
        anchor_embeddings = model.encode(anchor_responses_text, convert_to_tensor=True).cpu();
        response_embeddings = model.encode(response_texts, convert_to_tensor=True).cpu();
    } elif embedder == "USE" {
        import:py tensorflow_hub as hub;
        model = hub.load("https://tfhub.dev/google/universal-sentence-encoder/4");
        if not isinstance(anchor_responses_text, list){
            anchor_responses_text = [anchor_responses_text];
        }
        response_texts = [text for text in response_texts if isinstance(text, str)];
        anchor_embeddings = model(anchor_responses_text).numpy().tolist();
        response_embeddings = model(response_texts).numpy().tolist();
    } elif embedder == "USE_QA" {
        import:py tensorflow_hub as hub;
        model = hub.load("https://tfhub.dev/google/universal-sentence-encoder-qa/3");
        anchor_embeddings = model.signatures['question_encoder'](tf.constant([anchor_responses_text]))['outputs'];
        response_embeddings = model.signatures['response_encoder'](input=tf.constant(response_texts), context=tf.constant(response_texts))['outputs'];
    }

    return (anchor_embeddings, response_embeddings);
}


:can:calculate_similarity_score (anchor_embeddings:list, response_embeddings:list, scorer:str) {
    anchor_embeddings = np.array(anchor_embeddings);
    response_embeddings = np.array(response_embeddings);
    scores = [];

    if scorer == "cos_sim" {
        for anchor_embedding in anchor_embeddings {
            anchor_embedding_reshaped = anchor_embedding.reshape(1, -1);
            similarities = cosine_similarity(anchor_embedding_reshaped, response_embeddings).flatten();
            scores.append(similarities);
        }
        return scores;
    } else {
        st.error(f"Scorer '{scorer}' is not supported.");
        return None;
    }
}


:can:display_results(basedir:str,heatmap_placeholder:st, selected_prompt:str=None) {
    heat_map(basedir, "A/B Testing", heatmap_placeholder, selected_prompt);
}


:can:process_user_selections(selected_prompt:str = None){
    with open(st.session_state.distribution_file,"r") as fp{distribution = json.load(fp);}
    with open(os.path.abspath(".human_eval_config/responses.json"),"r") as fp{responses_dict = json.load(fp);}
    with open(os.path.abspath(".human_eval_config/models_responses.json"),"r") as fp{models_responses_dict = json.load(fp);}
    config_name = f"{st.session_state['anchor_model']}_{st.session_state['embedder']}_{st.session_state['scorer']}";
    basedir = Path(os.path.abspath(f"sim_results/{config_name}"));
    results_exist = basedir.exists();
    heatmap_placeholder = st.empty();
    if not results_exist {
        basedir.mkdir(parents=True, exist_ok=True);
        results = [];
        id=0;
        for (prompt_id, question_sets) in distribution.items() {
            worker_set= {
                    "worker_id":id,
                    "question_set_id":list(distribution.keys())[id],
                    "evals":[],
                    "start_time": time.time(),
                    "end_time":0,
                    "question_index": 0
                };
                evals = [];
            for (ind,question_set) in enumerate(question_sets) {
                prompt_id = question_set[0];
                responses = question_set[1];
                anchor_reponses_id = models_responses_dict[prompt_id][st.session_state.anchor_model];
                best_model = calculate_embedding_score(responses=responses, anchor_reponses_id=anchor_reponses_id,responses_dict=responses_dict);
                worker_set["evals"].append({"result": { 
                        "overall": "Response A" if best_model==0 else "Response B",
                        'feedback': ""
                    },
                    "time": time.time(),
                    "question": question_set
                });
                worker_set["question_index"]+=1;
            }
            worker_set["end_time"] = time.time();
            with open(f"{os.path.join(basedir, id)}.json", "w") as output {
                json.dump(worker_set, output,indent=4);
            }
            id+=1;
        }
    }elif not selected_prompt{
        display_results(basedir, heatmap_placeholder, selected_prompt);
    }else{

        display_results(basedir, heatmap_placeholder);
    }

}


:can:calculate_embedding_score(responses: list, anchor_reponses_id: dict, responses_dict: dict) -> None {
    anchor_reponses_text = [responses_dict[resp_id] for resp_id in anchor_reponses_id];
    response_texts = [responses_dict[resp_id] for resp_id in responses.values()];
    if not st.session_state['scorer'] == "sem_bleu" {
        (anchor_embeddings, response_embeddings) = generate_embeddings(anchor_reponses_text,response_texts, st.session_state['embedder']);
        scores = calculate_similarity_score(anchor_embeddings, response_embeddings, st.session_state['scorer']);
        average_scores = np.mean(scores, axis=0);
    } else {
        model = SentenceTransformer('all-MiniLM-L6-v2');
        average_scores = semantic_bleu_score(anchor_reponses_text,response_texts, model);
    }
    best_response_idx = np.argmax(average_scores);
    return best_response_idx;
}

:can:embed_sentence (sentence:str, model:SentenceTransformer) {
    return model.encode(sentence, convert_to_tensor=True);
}


:can:compute_bleu_score (reference:str, candidate:str) {
    reference_tokens = word_tokenize(reference);
    candidate_tokens = word_tokenize(candidate);
    smoothie = SmoothingFunction().method4;
    bleu_score = sentence_bleu(reference_tokens, candidate_tokens, smoothing_function=smoothie);
    return bleu_score;
}


:can:semantic_bleu_score (anchor_responses_text:list, response_texts:list, model: SentenceTransformer , ngram_size:int=4, scaling_factor:float=1, bleu_weight:float=0.5) {
    scores = [];
    for candidate in response_texts {
        anchor_score=[];
        for references in anchor_responses_text{
            ref_ngrams = list(ngrams(references.split(), n=ngram_size));
            cand_ngrams = list(ngrams(candidate.split(), n=ngram_size));

            if not ref_ngrams or not cand_ngrams {
                print("Empty n-grams detected. Skipping this candidate.");
                continue;
            }
            ref_embeddings = [embed_sentence(' '.join(ngram), model).cpu().numpy() for ngram in ref_ngrams];
            cand_embeddings = [embed_sentence(' '.join(ngram), model).cpu().numpy() for ngram in cand_ngrams];
            ref_tensor = tensor(ref_embeddings);
            cand_tensor = tensor(cand_embeddings);
            if ref_tensor.size(0) == 0 or cand_tensor.size(0) == 0 {
                print("Empty embeddings detected. Skipping this candidate.");
                continue;
            }
            cosine_scores = cosine_similarity(ref_tensor, cand_tensor).flatten();
            sem_scores = cosine_scores * scaling_factor;
            bleu_score = compute_bleu_score(references, candidate);
            if isinstance(bleu_score, (list, np.ndarray)) {
                bleu_score = np.mean(bleu_score);
            }
            adjusted_bleu = np.mean(sem_scores) + bleu_weight * bleu_score;
            anchor_score.append(adjusted_bleu);
        }
        scores.append(np.nanmean(adjusted_bleu));
    }
    return scores;
}
