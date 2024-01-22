import:py streamlit as st;
import:py from datetime, datetime;
import:py os;
import:py json;
import:py uuid;

with entry {
    if "config" not in st.session_state {
        if os.path.exists("config.json") {
            config = json.load(open("config.json"));
        } else {
            config = {
                "hv_method": "A/B Testing",
                "config": {
                    "n_queries": 10,
                    "fixed_model_name": None,
                    "n_options": 2,
                    "ability_to_tie": True,
                    "data_sources": os.listdir("data") if os.path.exists("data") else []
                }
            };
        }
        st.session_state.config = config;
    }
}

can setup {
    st.header("Human Evaluation Setup");
    st.caption("This is the setup page for the human eval. You can change the configuration and then click save to save the configuration.");

    st.subheader("Human Evaluation Method");
    (hv_method_col, hv_method_view_col) = st.columns(2);
    with hv_method_col {
        hv_method = st.selectbox("Select the human evaluation method", ["A/B Testing"], index=["A/B Testing"].index(st.session_state.config["hv_method"]));
    }
    with hv_method_view_col {
        st.caption("The following is a preview of the human evaluation method.");
        if hv_method == "A/B Testing" {
            st.caption("A/B Testing is a method where the user is shown two options and they have to choose the better one. This is repeated for a number of times and the option with the most votes wins.");
            # TODO: Replace with actual preview image
        }
    }

    st.subheader("Human Evaluation Configuration");
    (hv_config_col, hv_config2_col) = st.columns(2);
    with hv_config_col {
        n_queries = st.number_input("Number of queries", min_value=1, max_value=100, value=st.session_state.config["config"]["n_queries"], step=1);
        fixed_model_name = st.text_input("Fixed model name", value=st.session_state.config["config"]["fixed_model_name"]);
        n_options = st.number_input("Number of options", min_value=2, max_value=5, value=st.session_state.config["config"]["n_options"], step=1);
        n_workers = st.number_input("Number of workers", min_value=10, max_value=2000, step=1);

        json_files = [f for f in os.listdir("data") if f.endswith(".json")] if os.path.exists("data") else [];
        data_sources = st.multiselect("Data sources", json_files, default=st.session_state.config["config"]["data_sources"]);
        if n_options == 2 {
            ability_to_tie = st.selectbox("Ability to tie", ["Allow", "Not Allowed"], index=(0 if st.session_state.config["config"]["ability_to_tie"] else 1));
        } else {
            ability_to_tie = False;
        }
    }
    with hv_config2_col {
        if n_options == 2 {
            st.caption("Use the following calculator to calculate the minimum number of responses needed for the human evaluation for one prompt.");
            n_models = st.number_input("Number of models", min_value=1, max_value=100, step=1);
            n_questions_per_worker = st.number_input("Number of questions per worker", min_value=2, max_value=100, step=1);

            if st.button("Calculate") {
                (min_n_responses_needed_per_model, n_model_pairs) = sanity_check(n_models, n_workers, n_questions_per_worker);
                st.write("Minimum number of responses needed per model for even distribution: ", min_n_responses_needed_per_model);
                st.write("Number of model pairs: ", n_model_pairs);
            }
        } else {
            st.caption("The calculator is not available for more than 2 options.");
        }
    }

    uploaded_json_files = st.file_uploader("Upload data sources", accept_multiple_files=True, <>type="json");
        if uploaded_json_files {
            os.makedirs("data", exist_ok=True);
            for uploaded_json_file in uploaded_json_files {
                json_file = json.load(uploaded_json_file);
                json.dump(json_file, open(os.path.join("data", uploaded_json_file.name), "w"));
            }
            st.session_state.config["config"]["data_sources"] = [x for x in os.listdir("data") if x.endswith(".json")];
        }

    if st.button("Save") and data_sources {
        config = {
            "hv_method": hv_method,
            "config": {
                "n_queries": n_queries,
                "fixed_model_name": fixed_model_name,
                "n_options": n_options,
                "ability_to_tie": (ability_to_tie == "Allow"),
                "data_sources": data_sources
            }
        };
        with st.spinner("Creating Necessary Files...") {
            responses = {};
            models_info = {};
            prompts = {};
            for data_source in data_sources {
                with open(os.path.join("data", data_source)) as f {
                    data = json.load(f);
                    prompt = data["prompt"];
                    prompt_uid = str(uuid.uuid4());
                    prompts[prompt_uid] = prompt;
                    prompt_disc = data["prompt_disc"];
                    for model in data["ouputs"] {
                        model_responses = [];
                        for response in model["responses"] {
                            uid = str(uuid.uuid4());
                            responses[uid] = response;
                            model_responses.append(uid);
                        }
                        models_info[prompt_uid].append({
                            "prompt_disc": prompt_disc,
                            "model_name": model["model_name"],
                            "responses": model_responses
                        });
                    }
                }
            }
            question_pairs = get_question_pairs(models_info);

            with open("responses.json", "w") as f {
                json.dump(responses, f, indent=2);
            }
            with open("models_info.json", "w") as f {
                json.dump(models_info, f, indent=2);
            }
            with open("prompts.json", "w") as f {
                json.dump(prompts, f, indent=2);
            }
            with open("question_pairs.json", "w") as f {
                json.dump(question_pairs, f, indent=2);
            }
        }
        st.session_state.config = config;
        json.dump(config, open("config.json", "w"));
        st.toast("Saved!");
    }
}