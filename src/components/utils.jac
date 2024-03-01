import:py requests;
import:py json;
import:py os;
import:py shutil;
import:py time;
import:py streamlit as st;
import:py from yaspin, yaspin;
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
        with yaspin(text=f"Running experiment for {model_name} ({i+1}/{num_samples})...", color="yellow") {
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
