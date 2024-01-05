include:jac utils;

import:py streamlit as st;
import:py from datetime, datetime;
import:py uuid;

with entry {
    st.set_page_config(page_title="SLAM Tool", page_icon=":rocket:", layout="wide");
    st.title("SLAM Tool");

    if "messages" not in st.session_state {
        st.session_state.messages = [];
    }

    cols = st.columns(4);

    # Context Input
    cols[0].subheader("Context Input");
    context_files = [f for f in os.listdir("./context_input/") if f.endswith(".json")];
    selected_context = cols[0].selectbox("Choose a context input:", context_files);

    #Features
    cols[1].subheader("Feature");
    features = ["myca_peptalk", "myca_new_user_group_recs", "myca_new_user_peptalk"];
    selected_feature = cols[1].selectbox("Choose a feature:", features);

    # Load in the latest config for this feature  
    if selected_feature {
        feature_dir = os.path.join("./features/", selected_feature, "latest");
        feature_config_json = os.path.join(feature_dir, "config.json");
        with open(feature_config_json, "r") as f {
            feature_config = json.load(f);
        }
    }

    # LLM
    cols[2].subheader("LLM");
    selected_llm = cols[2].selectbox("Choose a LLM:", llms);

    for state in ["new_config", "full_prompt", "response", "context", "query_in"] {
        if state in st.session_state {
            st.session_state[state] = None;
        }
    }

    # Chat window
    st.header("Chat with Myca");
    # Display chat messages from history on app rerun
    for message in st.session_state.messages {
        with st.chat_message(message["role"]) {
            st.markdown(message["content"]);
        }
    }

    experiment_mode = st.checkbox("Experiment Mode?");
    if experiment_mode {
        st.session_state["experiment_id"] = str(uuid.uuid4()) if st.session_state.get("experiment_id") is None else st.session_state["experiment_id"];
        if st.button("Start new experiment") {
            st.session_state["experiment_id"] = str(uuid.uuid4());
        }
        os.makedirs(os.path.join("experiments", st.session_state["experiment_id"]), exist_ok=True);
        num_samples = st.slider("Number of samples", min_value=5, max_value=20, value=1);
        run_all = st.checkbox("Run for all models except OpenAI?");
        if st.button("Pull Ollama Models") {
            for model in llms[2:] {
                (model_provider, model_name) = model.split("/");
                if model_provider != "ollama" {
                    continue;
                }
                st.info(f"Pulling {model_name}...");
                os.system(f"ollama pull {model_name}");
            }
        }
    }

    # React to user input
    if query_in := st.chat_input("Type here...") {
        # Display user message in chat container
        st.chat_message("user").markdown(query_in);
        st.session_state.query_in = query_in;
        # Add user message to chat history
        st.session_state.messages.append({"role": "user", "content": query_in});

        # Load the context
        if selected_context {
            st.session_state.context = load_context(selected_context);
        }

        # Override LLM selection
        if selected_llm and selected_llm != "use config" {
            new_config = True;
            (feature_config["provider_name"], feature_config["model_name"]) = selected_llm.split("/");
        }

        with st.spinner("") {
            call_action(action="load_engine", config=feature_config, reload=True);
            ret = call_action(
                action="query",
                feature_name=feature_config["feature_name"],
                query_context=st.session_state.context,
                query=query_in
            );
        }

        st.session_state.response = ret["response"];
        st.session_state.full_prompt = ret["full_prompt"];

        if experiment_mode {
            llms_to_run = llms.copy()[2:] if run_all else [selected_llm];
            for model in llms_to_run {
                (feature_config["provider_name"], feature_config["model_name"]) = model.split("/");
                call_action(action="load_engine", config=feature_config, reload=True);
                with st.spinner(f"Running experiment for {feature_config['model_name']}") {
                    results = run_experiment(
                        query=query_in,
                        feature_name=feature_config["feature_name"],
                        model_name=feature_config["model_name"],
                        query_context=st.session_state.context,
                        num_samples=num_samples
                    );
                    results_path = os.path.join("experiments",st.session_state["experiment_id"],f"conv_{datetime.now().strftime('%Y-%m-%d_%H:%M:%S')}_{feature_config['model_name']}");
                    with open(results_path, "w") as f {
                        json.dump(results, f, indent=2);
                    }
                    st.info(f"{feature_config['model_name']}'s avg. response time: {results['avg_time']}s");
                }
            }
        }

        with st.chat_message("assistant") {
            st.markdown(st.session_state.response);
        }
        with st.expander("Full prompt") {
            st.text(wrap_text(ret["full_prompt"], 120));
        }

        st.session_state.messages.append({"role": "assistant", "content": st.session_state.response});
    }

    # Save conversation
    if st.button("Save conversation") {
        save_conv(
            feature_name=selected_feature,
            feature_config=feature_config,
            conv={
                "query": st.session_state.query_in,
                "full_prompt": st.session_state.full_prompt,
                "response": st.session_state.response,
                "context": st.session_state.context,
                "timestamp": datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
            },
            new_config=st.session_state.new_config
        );
    }
}