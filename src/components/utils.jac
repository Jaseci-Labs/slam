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

can parse_worker_data(workers_data_dir:str, distribution_file:str, response_file:str) {
    with open(distribution_file, "r") as fp{distribution = json.load(fp);}
    with open(response_file, "r") as fp{all_responses = json.load(fp);}
    out_dataset=[];

    for filename in os.listdir(workers_data_dir) {
        file_path = os.path.join(workers_data_dir, filename);
        if os.path.isfile(file_path){
            with open(file_path, "r") as fp{worker_data = json.load(fp);}
            if "question_index" in worker_data and worker_data["question_index"] == 10 {
                curr_distribution_set = distribution.get(worker_data["question_set_id"], None);
                if curr_distribution_set is not None {
                    curr_worker_data_set = [];
                    for (i, curr_worker_data) in enumerate(worker_data["evals"]) {
                        curr_set = curr_worker_data.get("question");
                        model_names = list(curr_set[1].keys());
                        (model_a, response_a_id) = (model_names[0], curr_set[1][model_names[0]]);
                        (model_b, response_b_id) = (model_names[1], curr_set[1][model_names[1]]);
                        response_a = all_responses.get(response_a_id, None);
                        response_b = all_responses.get(response_b_id, None);
                        curr_resp_contruct = {"model_a": model_a, "response_a": response_a, "model_b": model_b, "response_b": response_b};
                        curr_resp_contruct.update(curr_worker_data["result"]);
                        curr_resp_contruct.update({"prompt_id": curr_set[0]});
                        if i == 0 {
                            start_time = datetime.fromtimestamp(worker_data["start_time"]);
                        }
                        end_time = datetime.fromtimestamp(curr_worker_data["time"]);
                        curr_resp_contruct.update(
                            {"time_taken": (end_time - start_time).total_seconds()}
                        );
                        start_time = end_time;
                        curr_worker_data_set.append(curr_resp_contruct);
                    }
                    out_dataset.append({worker_data["worker_id"]: curr_worker_data_set});
                }
            }
        }
    }
    return out_dataset;
}
