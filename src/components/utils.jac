import:py requests;
import:py json;
import:py os;
import:py shutil;
import:py time;
import:py streamlit as st;
import:py from datetime, datetime;


glob ACTION_SERVER_URL = os.environ.get("ACTION_SERVER_URL","http://localhost:8000/");
glob OLLAMA_SERVER_URL = os.environ.get("OLLAMA_SERVER_URL","http://localhost:11434/");

can call_action(action:str, **kwargs: dict) -> dict {
    url = f"{ACTION_SERVER_URL}{action}";
    response = requests.post(url, json=kwargs);
    return response.json();
}

can check_query_engine -> bool {
    try {
        ret = requests.get(ACTION_SERVER_URL);
        return ret.status_code == 200;
    } except Exception as e {
        return False;
    }
}

can check_ollama_server -> bool {
    try {
        ret = requests.get(OLLAMA_SERVER_URL);
        return ret.status_code == 200;
    } except Exception as e {
        return False;
    }
}

can load_engine(provider_name:str, model_name:str, temperature:float, prompt_template:str) -> bool {
    config = {
        "provider_name": provider_name,
        "model_name": model_name,
        "temperature": temperature,
        "prompt_template": prompt_template
    };
    ret = call_action(action="load_engine", config = config);
    return True;
}

can run_inference(model_name:str, num_samples:int, payload:dict) -> dict {
    outputs = [];
    full_prompt = None;
    for i in range(num_samples) {
        try {
            start_time = time.time();
            ret = call_action(action="query", payload= payload);
            outputs.append({"response": ret["response"], "time": time.time() - start_time});
            if not full_prompt {
                full_prompt = ret["full_prompt"];
            }
        } except Exception as e {
            outputs.append({"response": str(e), "time": -1});
        }
    }
    avg_time = sum([o["time"] for o in outputs]) / len(outputs);
    return {
        "outputs": outputs,
        "full_prompt": full_prompt,
        "avg_time": avg_time,
        "model_name": model_name
    };
}

glob llms = [
    "openai/gpt-4",
    "ollama/starling-lm:7b",
    "ollama/mistral:7b-instruct",
    "ollama/zephyr:7b-beta",
    "ollama/neural-chat:7b",
    "ollama/orca-mini:3b",
    "ollama/llama2:7b-chat",
    "ollama/stablelm-zephyr:3b",
    "ollama/falcon:7b-instruct",
    "ollama/orca2:7b",
    "ollama/openchat:7b-v3.5",
    "ollama/vicuna:7b"
    # Add your ollama models here
];

can login {
    (logo_col, login_col) = st.columns(2);
    with logo_col {
        st.header("Welcome to SLaM Tool!");
        st.info("SLaM Tool allows you to run human evaluations and llm evaluations on various propietary and open-source language models.");
        st.info("Please login to access the dashboard, evaluation and other features.");
    }
    with login_col {
        with st.form(key='my_form') {
            username = st.text_input('Username');
            password = st.text_input('Password');
            if st.form_submit_button('Login') {
                try {
                    if username == os.environ.get("SLAM_ADMIN_USERNAME") and password == os.environ.get("SLAM_ADMIN_PASSWORD"){
                        st.session_state.admin_privileges = True;
                        st.rerun();
                    } else {st.error("Invalid username or password");}
                } except Exception as e {st.error("Admin Account not configured. Please contact the administrator.");}
            }
        }
    }
}

can map_prompt_names_to_ids(prompt_data_dir:str, prompt_info_file:str) {
    with open(prompt_info_file, "r") as file {
        prompt_info = json.load(file);
    }
    prompt_info = [{prompt["prompt_id"]: prompt["prompt"]} for prompt in prompt_info];
    prompt_ids = {};
    for filename in os.listdir(prompt_data_dir) {
        use_case_name = "_".join(filename.split(".")[0].split("_")[:-1]);
        file_path = os.path.join(prompt_data_dir, filename);
        with open(file_path, "r") as file {
            prompt_data = json.load(file)["prompt"];
            for inv_prompt in prompt_info {
                if (prompt_data == list(inv_prompt.values())[0]) {
                    prompt_ids[use_case_name] = list(inv_prompt.keys())[0];
                }
            }
        }
    }
    return prompt_ids;
}

can check_engine_status {
    query_engine_status = check_query_engine();
    ollama_server_status = check_ollama_server();
    (query_engine_status_col, ollama_server_status_col) = st.columns(2);

    if query_engine_status {query_engine_status_col.success('Query Engine is Running');}
    else {query_engine_status_col.error('Query Engine is not Running');}

    if ollama_server_status {ollama_server_status_col.success('Ollama Server is Running');}
    else {ollama_server_status_col.error('Ollama Server is not Running');}

    return query_engine_status;
}

can generate_performance_data(
    formatted_output:dict, 
    all_models:list, 
    prompt_id:str, 
    criteria:list) {
    if (not criteria) {
        criteria = [
            "overall",
            "clarity",
            "intelligence",
            "likability",
            "trustworthiness"
        ];
    }

    model_performance = {
        model: {
            criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria
        } for model in all_models
    };
    preference_matrix = {
        criterion: {
            model: {
                other_model: 0 for other_model in all_models if other_model != model
            } for model in all_models
        } for criterion in criteria
    };
    for outputs in formatted_output {
        if (prompt_id == "all_combined" or outputs["prompt_id"] == prompt_id) {
            for response in outputs["responses"] {
                model1 = response["model_a"];
                model2 = response["model_b"];
                for crit in criteria {
                    result = response.get(crit);
                    if (result == "Response A") {
                        model_performance[model1][crit]["wins"] += 1;
                        model_performance[model2][crit]["losses"] += 1;
                        preference_matrix[crit][model1][model2] += 1;
                    } elif (result == "Response B") {
                        model_performance[model1][crit]["losses"] += 1;
                        model_performance[model2][crit]["wins"] += 1;
                        preference_matrix[crit][model2][model1] += 1;
                    } else {  # Ties
                        model_performance[model1][crit]["ties"] += 1;
                        model_performance[model2][crit]["ties"] += 1;
                    }
                }
            }
        }
    }

    return (model_performance, preference_matrix, criteria);
}

can format_responses_by_prompt(workers_data_dir:str, distribution_file:str, response_file:str) {
    out_dataset = {};

    with open(distribution_file, "r") as file {
        distribution = json.load(file);
    }
    with open(response_file, "r") as file {
        all_responses = json.load(file);
    }
    for filename in os.listdir(workers_data_dir) {
        file_path = os.path.join(workers_data_dir, filename);
        if (os.path.isfile(file_path)) {
            try {
                with open(file_path, "r") as file {
                    worker_data = json.load(file);
                }
            } except Exception as e {
                print(f"Error reading {file_path}: {e}");
                continue;
            }
            if ("question_index" in worker_data and worker_data["question_index"] == 10) {
                curr_distribution_set = distribution.get(worker_data["question_set_id"], None);
                if (curr_distribution_set != None) {
                    for (i, curr_worker_data) in enumerate(worker_data["evals"]) {
                        curr_worker_data = worker_data["evals"][i];
                        curr_set = curr_worker_data.get("question");
                        prompt_id = curr_set[0];
                        model_names = list(curr_set[1].keys());
                        (model_a, response_a_id) = (
                            model_names[0],
                            curr_set[1][model_names[0]]
                        );
                        (model_b, response_b_id) = (
                            model_names[1],
                            curr_set[1][model_names[1]]
                        );
                        response_a = all_responses.get(response_a_id, None);
                        response_b = all_responses.get(response_b_id, None);

                        curr_resp_contruct = {
                            "model_a": model_a,
                            "response_a": response_a,
                            "model_b": model_b,
                            "response_b": response_b,
                            "worker_id": worker_data["worker_id"]
                        };
                        curr_resp_contruct.update(curr_worker_data["result"]);
                        if (i == 0) {
                            start_time = datetime.fromtimestamp(worker_data["start_time"]);
                        }
                        end_time = datetime.fromtimestamp(curr_worker_data["time"]);
                        curr_resp_contruct.update({
                            "time_taken": (end_time - start_time).total_seconds()
                        });
                        start_time = end_time;
                        if (prompt_id not in out_dataset) {
                            out_dataset[prompt_id] = [];
                        }
                        out_dataset[prompt_id].append(curr_resp_contruct);
                    }
                }
            }
        }
    }

    formatted_output = [
        {"prompt_id": prompt_id, "responses": responses} for (prompt_id, responses) in out_dataset.items()
    ];
    return formatted_output;
}

