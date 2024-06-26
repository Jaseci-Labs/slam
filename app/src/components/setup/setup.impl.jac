'''Evaluation Setup Implementations'''
import:py streamlit as st;
import:py os;
import:py json;
import:py uuid;
import:py math;
import:py itertools;
import:py random;
import:py pandas as pd;

:can:<>init {
    if "config" not in st.session_state {
        if os.path.exists(os.path.join(".human_eval_config", "config.json")) {
            config = json.load(open(os.path.join(".human_eval_config", "config.json")));
        } else {
            config = {"hv_method": "A/B Testing", "config": {"n_workers": 100, "n_questions_per_worker": 10, "ability_to_tie": "Allow", "data_sources": None, "evenly_distributed": False, "show_captcha": True, "completion_code": str(uuid.uuid4())}};
        }
        st.session_state.config = config;
    }
}

:can:hv_evaluation_method_selector {
    eval_methods = {"A/B Testing": {"desc": "A/B Testing is a method where the evaluator is shown two options and they have to choose the better one. This is repeated for a number of times and the option with the most votes wins.", "image": "https://i.ibb.co/kXwypbc/image.png"}, "A/B Testing with Criterions": {"desc": "A/B Testing with Criterions is a method where the user is shown two options and they have to choose the better one for each criterion (clarity, fluency, etc.).", "image": "https://i.ibb.co/JF6Q3F3/image.png"}};
    criterias = None;
    st.subheader("Evaluation Methodology");
    (hv_method_col, hv_method_view_col) = st.columns(2);
    with hv_method_col {
        hv_method = st.selectbox("Select the Evaluation method", list(eval_methods.keys()), index=list(eval_methods.keys()).index(st.session_state.config["hv_method"]));
        st.caption(eval_methods[hv_method]["desc"]);
        if hv_method == "A/B Testing with Criterions" {
            criteria_df = pd.DataFrame([{"Criteria": "clarity", "Description": "Which has better clarity?"}, {"Criteria": "intelligence", "Description": "Which is more intelligent?"}, {"Criteria": "likability", "Description": "Which is more likable?"}, {"Criteria": "trustworthy", "Description": "Which is more trustworthy?"}, {"Criteria": "overall", "Description": "Which is better overall?"}]);
            edited_df = st.data_editor(criteria_df, num_rows="dynamic");
            criterias = edited_df.to_dict(orient="records");
        }
    }
    with hv_method_view_col {
        st.caption("The following is a preview of the human evaluation method.");
        st.image(eval_methods[hv_method]["image"], use_column_width=True);
    }
    return (hv_method, criterias);
}

:can:sanity_check (n_models: int, n_usecases: int, n_workers: int, n_questions_per_worker: int){
    n_model_pairs = n_models * (n_models - 1) / 2;
    min_n_responses_needed_per_model = int(math.ceil(math.sqrt(n_workers * n_questions_per_worker / n_usecases / float(n_model_pairs))));
    return (min_n_responses_needed_per_model, n_model_pairs);
}

'''Add Data Sources to the Configurator'''
can add_data_sources {
    with st.form("upload_datasources", clear_on_submit=True) {
        uploaded_json_files = st.file_uploader("Upload data sources", accept_multiple_files=True, <>type="json");
        submitted = st.form_submit_button("Submit");
        if submitted and uploaded_json_files {
            os.makedirs("data", exist_ok=True);
            for uploaded_json_file in uploaded_json_files {
                json_file = json.load(uploaded_json_file);
                json.dump(json_file, open(os.path.join("data", uploaded_json_file.name), "w"));
            }
            st.rerun();
        }
    }
}

:can:hv_configurator {
    st.subheader("Human Evaluation Configuration");
    (hv_config_1_col, hv_config_2_col, hv_config_3_col) = st.columns(3);
    with hv_config_1_col {
        n_workers = st.number_input("Number of Evaluators", min_value=10, step=1, value=st.session_state.config["config"]["n_workers"], help="Number of Evaluators going to participate");
        n_questions_per_worker = st.number_input("Number of questions per evaluator", min_value=2, max_value=100, step=1, value=st.session_state.config["config"]["n_questions_per_worker"], help="Number of questions shown to an Evaluator");
        show_captcha = st.checkbox("Show Captcha (Human Verification)", value=st.session_state.config["config"]["show_captcha"]);
        ability_to_tie = st.selectbox("Ability to Choose Both", ["Allow", "Not Allowed"], index=["Allow", "Not Allowed"].index(st.session_state.config["config"]["ability_to_tie"]), help="Select whether the evaluator can choose both options as the same.");
        evenly_distributed = st.checkbox("Usecases are Evenly distributed among the evaluators", value=st.session_state.config["config"]["evenly_distributed"], help="If checked, the usecases will be evenly distributed among the workers. for example, if there are 2 usecases and 10 workers, each worker will get 1 question from each usecase. If not checked, the questions will be randomly distributed.");
    }
    with hv_config_2_col {
        json_files = [f  for f in os.listdir("data") if f.endswith(".json")] if os.path.exists("data") else [];
        data_sources = st.multiselect("Data sources (Usecases)", json_files, default=st.session_state.config["config"]["data_sources"], help="Select the data sources for the evaluation. Each file should represent a usecase (sigle prompt) you want to evaluate.");
        add_data_sources();
    }
    with hv_config_3_col {
        st.caption("Following is to check if the configuration is valid.");
        n_models = st.number_input("Number of models", min_value=2, max_value=100, step=1, help="Number of models you want to evaluate.");
        n_responses_per_model = st.number_input("Number of responses per model", min_value=1, max_value=100, step=1, help="Number of responses per model in the data sources.");
        try  {
            (min_n_responses_needed_per_model, n_model_pairs) = sanity_check(n_models, len(data_sources), n_workers, n_questions_per_worker);
            st.write("Minimum number of responses needed per model per usecase for even distribution: ", min_n_responses_needed_per_model);
            if n_responses_per_model < min_n_responses_needed_per_model {
                st.warning("Number of responses per model is less than the minimum required for even distribution. Try increasing the number of responses per model.");
            }
        } except Exception {
            st.warning("Configuration is not valid. Please check the values.");
        }
    }
    return (n_workers, ability_to_tie, data_sources, n_questions_per_worker, evenly_distributed, show_captcha);
}

:can:get_question_pairs(models_responses_all: dict) -> list {
    n_usecases = len(models_responses_all);
    models = list(list(models_responses_all.values())[0].keys());
    random.shuffle(models);
    n_workers = st.session_state.config["config"]["n_workers"];
    n_questions_per_worker = st.session_state.config["config"]["n_questions_per_worker"];
    unique_model_pairs = list(itertools.combinations(models, 2));
    k = int(math.ceil(n_workers * n_questions_per_worker / n_usecases / float(len(unique_model_pairs))));
    question_pairs = [];
    for (prompt_id, models_responses) in models_responses_all.items() {
        for model_pair in unique_model_pairs {
            model_a_responses = models_responses[model_pair[0]];
            model_b_responses = models_responses[model_pair[1]];
            unique_question_pairs = list(itertools.product(model_a_responses, model_b_responses));
            unique_question_pairs = random.sample(unique_question_pairs, k);
            for question_pair in unique_question_pairs {
                question_pairs.append((prompt_id, {model_pair[0]: question_pair[0], model_pair[1]: question_pair[1]}));
            }
        }
    }
    return question_pairs;
}

:can:get_distribution(question_pairs: list, n_workers: int, n_questions_per_worker: int) -> dict {
    need_to_be_evenly_distributed = st.session_state.config["config"]["evenly_distributed"];
    if not need_to_be_evenly_distributed {
        selected_question_pairs = random.sample(question_pairs, n_workers * n_questions_per_worker);
        random.shuffle(selected_question_pairs);
        worker_ids = [str(uuid.uuid4())  for _ in range(n_workers)];
        distribution = {worker_id: selected_question_pairs[i * n_questions_per_worker:(i + 1) * n_questions_per_worker]  for (i, worker_id) in enumerate(worker_ids)};
    } else {
        question_pairs_copy = question_pairs.copy();
        random.shuffle(question_pairs_copy);
        worker_ids = [str(uuid.uuid4())  for _ in range(n_workers)];
        distribution = {worker_id: []  for worker_id in worker_ids};
        prompt_infos = json.load(open(os.path.join(".human_eval_config", "prompt_info.json")));
        prompt_ids = [prompt_info["prompt_id"]  for prompt_info in prompt_infos];
        questions_per_usecase_per_worker = int(n_questions_per_worker / len(prompt_ids));
        for worker_id in worker_ids {
            for prompt_id in prompt_ids {
                x = 0;
                for (i, question_pair) in enumerate(question_pairs_copy) {
                    if question_pair[0] == prompt_id {
                        distribution[worker_id].append(question_pair);
                        question_pairs_copy.pop(i);
                        x+=1;
                    }
                    if x == questions_per_usecase_per_worker {
                        break;
                    }
                }
            }
        }
    }
    return distribution;
}

:can:create_neccessary_file(data_sources: list, _prompt_infos: dict) {
    with st.spinner("Creating Necessary Files...") {
        uid_responses = {};
        models_responses_all = {};
        prompt_infos = [];
        for data_source in data_sources {
            prompt_info = {};
            models_responses = {};
            with open(os.path.join("data", data_source)) as f {
                data = json.load(f);
                prompt_info["prompt"] = data["prompt"];
                prompt_info["prompt_disc"] = _prompt_infos[data_source]["prompt_disc"];
                prompt_info["prompt_id"] = _prompt_infos[data_source]["usecase_id"];
                prompt_info["prompt_simple_disc"] = _prompt_infos[data_source]["prompt_simple_disc"];
                for (model_name, responses) in data["outputs"].items() {
                    model_responses = [];
                    for response in responses {
                        uid = str(uuid.uuid4());
                        uid_responses[uid] = response;
                        model_responses.append(uid);
                    }
                    models_responses[model_name] = model_responses;
                }
            }
            prompt_infos.append(prompt_info);
            models_responses_all[_prompt_infos[data_source]["usecase_id"]] = models_responses;
        }
        json.dump(uid_responses, open(os.path.join(".human_eval_config", "responses.json"), "w"), indent=2);
        json.dump(models_responses_all, open(os.path.join(".human_eval_config", "models_responses.json"), "w"), indent=2);
        json.dump(prompt_infos, open(os.path.join(".human_eval_config", "prompt_info.json"), "w"), indent=2);
    }
    return models_responses_all;
}

:can:get_prompt_info(data_sources: list) {
    prompt_infos = {data_source: {}  for data_source in data_sources};
    with st.container(border=True) {
        st.subheader("Prompt Information");
        for data_source in data_sources {
            with st.expander(f"Usecase {data_source}", expanded=True) {
                with open(os.path.join("data", data_source)) as f {
                    data = json.load(f);
                }
                (tab_input, tab_preview) = st.tabs(["Prompt Information", "Preview"]);
                with tab_input {
                    prompt_infos[data_source]["usecase_id"] = st.text_input("Usecase Identifier", key=f"{data_source}_usecase_id", value=str(uuid.uuid4()), help="Unique ID for the usecase.");
                    prompt_infos[data_source]["prompt_disc"] = st.text_area("Human Evaluation Description (MarkDown)", key=f"{data_source}_prompt_disc", value=data.get("prompt_disc", ""), help="Display description of the prompt. Use markdown/html for Nice looks.");
                    prompt_infos[data_source]["prompt_simple_disc"] = st.text_area("Auto Evaluation Description", key=f"{data_source}_prompt_simple_disc", value="", help="Simple text description of the usecase. Note: This will be used in the Auto Evaluation.");
                }
                with tab_preview {
                    st.caption("Preview of the prompt description. Note: Following is a representation of what evaluators will see.");
                    st.markdown(prompt_infos[data_source]["prompt_disc"], unsafe_allow_html=True);
                }
            }
        }
    }
    return prompt_infos;
}
