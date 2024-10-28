import:py streamlit as st;
import:py os;
import:py json;
import:py time;
import from sklearn.metrics.pairwise {cosine_similarity}
import:py numpy as np;
import from ..dashboard.dashboard {heat_map}
import from pathlib {Path}
import from sentence_transformers {SentenceTransformer}
import from nltk.tokenize {word_tokenize}
import from nltk.translate.bleu_score {sentence_bleu}
import from nltk.translate.bleu_score {SmoothingFunction}
import from torch {tensor}
import from nltk {ngrams}
import:py tensorflow as tf;
import from collections {Counter}


:can:generate_embeddings(anchor_responses_text: list, response_texts: list, embedder: str) {
    anchor_embeddings = [];
    response_embeddings = [];
    if embedder == "SBERT" {
        model = SentenceTransformer('all-MiniLM-L6-v2');
        anchor_embeddings = model.encode(anchor_responses_text, convert_to_tensor=True).cpu();
        response_embeddings = model.encode(response_texts, convert_to_tensor=True).cpu();
    } elif embedder == "USE" {
        import:py tensorflow_hub as hub;
        model = hub.load("https://tfhub.dev/google/universal-sentence-encoder/4");
        if not isinstance(anchor_responses_text, list) {
            anchor_responses_text = [anchor_responses_text];
        }
        response_texts = [text  for text in response_texts if isinstance(text, str)];
        anchor_embeddings = model(anchor_responses_text).numpy().tolist();
        response_embeddings = model(response_texts).numpy().tolist();
    } elif embedder == "USE_QA" {
        import:py tensorflow_hub as hub;
        model = hub.load("https://tfhub.dev/google/universal-sentence-encoder-qa/3");
        if not isinstance(anchor_responses_text, list){anchor_responses_text = [anchor_responses_text];}
        for i in range(len(anchor_responses_text)){
            if not isinstance(anchor_responses_text[i], str){
                anchor_responses_text[i] = str(anchor_responses_text[i]);
            }
        }

        if not isinstance(response_texts, list){response_texts = [response_texts];}
        for i in range(len(response_texts)){
            if not isinstance(response_texts[i], str){
                response_texts[i] = str(response_texts[i]);
            }
        }
        anchor_embeddings = model.signatures['question_encoder'](input=tf.constant(anchor_responses_text))['outputs'];
        response_embeddings = model.signatures['response_encoder'](input=tf.constant(response_texts), context=tf.constant(response_texts))['outputs'];
    }
    return (anchor_embeddings, response_embeddings);
}


:can:calculate_similarity_score(anchor_embeddings: list, response_embeddings: list, scorer: str) {
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

:can:display_results(basedir: str, heatmap_placeholder: st, selected_prompt: str=None) {
    heat_map(basedir, "A/B Testing", heatmap_placeholder, selected_prompt);
}

:can:process_user_selections (selected_prompt: str=None) {
    with open(st.session_state.distribution_file, "r") as fp {
        distribution = json.load(fp);
    }
    with open(os.path.abspath(".human_eval_config/responses.json"), "r") as fp {
        responses_dict = json.load(fp);
    }
    with open(os.path.abspath(".human_eval_config/models_responses.json"), "r") as fp {
        models_responses_dict = json.load(fp);
    }
    config_name = f"{st.session_state['anchor_model']}_{st.session_state['embedder']}_{st.session_state['scorer']}";
    path_string = os.path.join("results", config_name);
    basedir = Path(os.path.abspath(path_string));
    heatmap_placeholder = st.empty();
    if not basedir.exists()
        or not any(basedir.glob('*.json')) {
        basedir.mkdir(parents=True, exist_ok=True);
        results = [];
        id = 0;
        for (prompt_id, question_sets) in distribution.items() {
            worker_set = {"worker_id": id, "question_set_id": list(distribution.keys())[id], "evals": [], "start_time": time.time(), "end_time": 0, "question_index": 0};
            evals = [];
            for (ind, question_set) in enumerate(question_sets) {
                prompt_id = question_set[0];
                responses = question_set[1];
                anchor_reponses_id = models_responses_dict[prompt_id][st.session_state.anchor_model];
                best_model = calculate_embedding_score(responses=responses, anchor_reponses_id=anchor_reponses_id, responses_dict=responses_dict);
                worker_set["evals"].append({"result": {"overall": "Response A" if best_model == 0 else "Response B", 'feedback': ""}, "time": time.time(), "question": question_set});
                worker_set["question_index"]+=1;
            }
            worker_set["end_time"] = time.time();
            with open(f"{os.path.join(basedir, str(id))}.json", "w") as output {
                json.dump(worker_set, output, indent=4);
            }
            id+=1;
        }
    } elif not selected_prompt {
        display_results(basedir, heatmap_placeholder, selected_prompt);
    } else {
        display_results(basedir, heatmap_placeholder);
    }
}

:can:calculate_embedding_score(responses: list, anchor_reponses_id: dict, responses_dict: dict) -> None {
    anchor_reponses_text = [responses_dict[resp_id]  for resp_id in anchor_reponses_id];
    response_texts = [responses_dict[resp_id]  for resp_id in responses.values()];
    if not st.session_state['scorer'] == "sem_bleu" {
        (anchor_embeddings, response_embeddings) = generate_embeddings(anchor_reponses_text, response_texts, st.session_state['embedder']);
        scores = calculate_similarity_score(anchor_embeddings, response_embeddings, st.session_state['scorer']);
        average_scores = np.mean(scores, axis=0);
    } else {
        model = SentenceTransformer('all-MiniLM-L6-v2');
        average_scores = semantic_bleu_score(anchor_reponses_text, response_texts, model);
    }
    best_response_idx = np.argmax(average_scores);
    return best_response_idx;
}

:can:embed_sentence(sentence: str, model: SentenceTransformer) {
    return model.encode(sentence, convert_to_tensor=True);
}
:can:simple_bleu(reference: str, candidate: str, n_gram: int=4) {
    reference_tokens = word_tokenize(reference);
    candidate_tokens = word_tokenize(candidate);
    reference_ngrams = [ngrams(reference_tokens, i) for i in range(1, n_gram+1)];
    candidate_ngrams = [ngrams(candidate_tokens, i) for i in range(1, n_gram+1)];

    weights = np.ones(n_gram) / n_gram;
    p_ns = [];

    n = min(len(reference_ngrams), len(candidate_ngrams)); 
    i = 0;
    while (i < n) {
        ref_ng = list(reference_ngrams[i]);  # Convert generator to list if necessary
        cand_ng = list(candidate_ngrams[i]);  # Convert generator to list if necessary
        ref_count = Counter(ref_ng);
        cand_count = Counter(cand_ng);

        count = sum((cand_count & ref_count).values());
        total = sum(cand_count.values());

        p_n = count / total if total > 0 else 0;
        p_ns.append(p_n);
        i = i + 1;
    }

    weights = np.array(weights);
    p_ns = np.array(p_ns);
    p_ns = np.log(p_ns, out=np.zeros_like(p_ns), where=(p_ns != 0));
    bleu = np.exp(np.sum(p_ns * weights));
    return bleu;
}

:can:compute_bleu_score(reference: str, candidate: str) {
    return simple_bleu(reference, candidate);
}


:can:semantic_bleu_score(anchor_responses_text: list, response_texts: list, model: SentenceTransformer, ngram_size: int=4, scaling_factor: float=1, bleu_weight: float=0.5) {
    scores = [];
    for candidate in response_texts {
        anchor_score = [];
        for references in anchor_responses_text {
            ref_ngrams = list(ngrams(references.split(), n=ngram_size));
            cand_ngrams = list(ngrams(candidate.split(), n=ngram_size));
            if not ref_ngrams or not cand_ngrams {
                print("Empty n-grams detected. Skipping this candidate.");
                continue;
            }
            ref_embeddings = [embed_sentence(' '.join(ngram), model).cpu().numpy()  for ngram in ref_ngrams];
            cand_embeddings = [embed_sentence(' '.join(ngram), model).cpu().numpy()  for ngram in cand_ngrams];
            ref_tensor = tensor(ref_embeddings);
            cand_tensor = tensor(cand_embeddings);
            if ref_tensor.size(0) == 0
                or cand_tensor.size(0) == 0 {
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
