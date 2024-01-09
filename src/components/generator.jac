import:py streamlit as st;
import:jac from components.utils, load_engine, run_inference, llms, check_query_engine, check_ollama_server;
import:py uuid;
import:py re;

with entry {
    if "run_id" not in st.session_state {
        st.session_state["run_id"] = uuid.uuid4();
    }
}

can generator {
    st.header('Response Generator');
    st.caption("This helps you to generate the necessary response for the given prompt template with given values for all the selected SLMs and propierity LLMs.");
    query_engine_status = check_query_engine();
    ollama_server_status = check_ollama_server();
    (query_engine_status_col, ollama_server_status_col) = st.columns(2);
    if query_engine_status {
        query_engine_status_col.success('Query Engine is Running');
    } else {
        query_engine_status_col.error('Query Engine is not Running');
    }
    if ollama_server_status {
        ollama_server_status_col.success('Ollama Server is Running');
    } else {
        ollama_server_status_col.error('Ollama Server is not Running');
    }

    st.subheader('Model Settings');
    selected_models = st.multiselect('Select Models', llms);
    (n_samples_temp_col, run_id_col) = st.columns(2);
    with n_samples_temp_col {
        (n_samples_col, temp_col) = st.columns(2);
        n_samples = n_samples_col.number_input('Number of Samples', 1, 100, 1);
        temp = temp_col.number_input('Temperature', 0.0, 1.0, 0.7);
    }
    st.session_state["run_id"] = run_id_col.text_input('Run ID', st.session_state["run_id"]);

    st.subheader('Prompt Setting');
    (prompt_template_col, prompt_values_col) = st.columns(2);
    prompt_template = prompt_template_col.text_area('Input Prompt Template', placeholder='Paste your template here', height=250);
    with prompt_values_col {
        st.caption('Input Prompt Values');
        arguments = {x:None for x in []};
        # arguments = {x:None for x in re.findall(r'\{([A-Za-z0-9_]+)\}', prompt_template)};
        if len(arguments) == 0 {
            st.info('No arguments found in the prompt template');
        }
        for arg in arguments.keys(){
            arguments[arg] = st.text_input(arg, key=arg);
        }
    }

    if len(selected_models) > 0 and prompt_template and all([x for x in arguments.values()]) {
        st.caption('Click the button below to generate the responses. This may take a while.');
        if st.button('Generate Responses') {
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
                    }
                } else {
                    st.error(f"Failed to load model {model_name}");
                }
            }
        }
    }
}