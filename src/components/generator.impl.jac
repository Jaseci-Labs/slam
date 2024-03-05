import:py os;
import:py streamlit as st;
import:py re;
import:py uuid;
import:py json;

import:jac from utils, load_engine, run_inference, check_engine_status, LLMS;

:can:<>init {
    os.makedirs('runs', exist_ok=True);
    if "run_id" not in st.session_state {
        st.session_state["run_id"] = uuid.uuid4();
    }
}

:can:model_settings {
    st.subheader('Model Settings');
    selected_models = st.multiselect('Select Models', LLMS);
    (n_samples_temp_col, run_id_col) = st.columns(2);
    with n_samples_temp_col {
        (n_samples_col, temp_col) = st.columns(2);
        n_samples = n_samples_col.number_input('Number of Samples', 1, 100, 1);
        temp = temp_col.number_input('Temperature', 0.0, 1.0, 0.7);
    }
    st.session_state["run_id"] = run_id_col.text_input('Run ID', st.session_state["run_id"]);
    return (selected_models, n_samples, temp);
}

:can:prompt_settings {
    st.subheader('Prompt Setting');
    (prompt_template_col, prompt_values_col) = st.columns(2);
    prompt_template = prompt_template_col.text_area('Input Prompt Template', placeholder='Paste your template here', height=250);
    with prompt_values_col {
        st.caption('Input Prompt Values');
        arguments = {x:None for x in re.findall(r'\{([A-Za-z0-9_]+)\}', prompt_template)};
        if len(arguments) == 0 {
            st.info('No arguments found in the prompt template');
        }
        for arg in arguments.keys(){
            arguments[arg] = st.text_input(arg, key=arg);
        }
    }
    return (prompt_template, arguments);
}

:can:generate_responses(selected_models: list, n_samples: int, temp: float, prompt_template: str, arguments: dict) -> None {
    os.makedirs(os.path.join("runs", st.session_state["run_id"]), exist_ok=True);
    for model in selected_models {
        (provider_name, model_name) = model.split('/');
        engine_loaded = False;
        with st.spinner(f"Loading model {model_name}...") {
            engine_loaded = load_engine(provider_name, model_name, temp, prompt_template);
        }
        if engine_loaded {
            with st.spinner(f"Generating responses for model {model_name}...") {
                response = run_inference(model_name, n_samples, arguments);
                st.success(f"Average Time Taken: {response['avg_time']}s for model {model_name}");
                with open(os.path.join("runs", st.session_state["run_id"], f"{model_name}.json"), 'w') as f {
                    json.dump(response, f, indent=2);
                }
            }
        } else {
            st.error(f"Failed to load model {model_name}");
        }
    }
}
