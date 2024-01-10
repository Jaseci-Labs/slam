import:py streamlit as st;
import:py from datetime, datetime;
import:py os;
import:py json;

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
                    "data_sources": []
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
        hv_method = st.selectbox("Select the human evaluation method", ["A/B Testing", "Ranking", "Preference Judgement"], index=["A/B Testing", "Ranking", "Preference Judgement"].index(st.session_state.config["hv_method"]));
    }
    # TODO: HV Method preview

    st.subheader("Human Evaluation Configuration");
    (hv_config_col, hv_config2_col) = st.columns(2);
    with hv_config_col {
        n_queries = st.number_input("Number of queries", min_value=1, max_value=100, value=st.session_state.config["config"]["n_queries"], step=1);
        fixed_model_name = st.text_input("Fixed model name", value=st.session_state.config["config"]["fixed_model_name"]);
        n_options = st.number_input("Number of options", min_value=2, max_value=5, value=st.session_state.config["config"]["n_options"], step=1);

        json_files = [f for f in os.listdir("data") if f.endswith(".json")] if os.path.exists("data") else [];
        data_sources = st.multiselect("Data sources", json_files, default=st.session_state.config["config"]["data_sources"]);
        ability_to_tie = st.checkbox("Able to Tie", value=st.session_state.config["config"]["ability_to_tie"]);
    }
    with hv_config2_col {
        uploaded_json_files = st.file_uploader("Upload data sources", accept_multiple_files=True);
        if uploaded_json_files {
            os.makedirs("data", exist_ok=True);
            for uploaded_json_file in uploaded_json_files {
                json_file = json.load(uploaded_json_file);
                json.dump(json_file, open(os.path.join("data", uploaded_json_file.name), "w"));
            }
        }
    }

    if st.button("Save") {
        config = {
            "hv_method": hv_method,
            "config": {
                "n_queries": n_queries,
                "fixed_model_name": fixed_model_name,
                "n_options": n_options,
                "ability_to_tie": ability_to_tie
            }
        };
        st.session_state.config = config;
        json.dump(config, open("config.json", "w"));
        st.toast("Saved!");
    }
}