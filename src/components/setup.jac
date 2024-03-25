import:py streamlit as st;
import:py os;
import:py from datetime, datetime;
import:py json;
import:py uuid;

can sanity_check(n_models: int, n_usecases: int, n_workers: int, n_questions_per_worker: int);

can get_question_pairs(models_responses_all: dict);

can get_distribution(question_pairs: list, n_workers: int, n_questions_per_worker: int);

can <>init;

can hv_evaluation_method_selector;

can hv_configurator;

can get_prompt_info(data_sources: list) -> dict;

can add_data_sources;

can create_neccessary_file(data_sources: list, _prompt_infos: dict);

can setup {
    <>init();
    st.header("Human Evaluation Setup");
    st.caption("This is the setup page for the human eval. You can change the configuration and then click save to save the configuration.");
    with st.container(border=True) {
        (hv_method, criterias) = hv_evaluation_method_selector();
    }
    with st.container(border=True) {
        (n_options, n_workers, ability_to_tie, data_sources, n_questions_per_worker, evenly_distributed, show_captcha) = hv_configurator();
        add_data_sources();
    }
    if data_sources {
        prompt_infos = get_prompt_info(data_sources);
        if st.button("Save") {
            os.makedirs(".human_eval_config", exist_ok=True);
            config = {"hv_method":hv_method, "config":{"n_workers":n_workers, "n_questions_per_worker":n_questions_per_worker, "n_options":n_options, "ability_to_tie":ability_to_tie, "data_sources":data_sources, "evenly_distributed":evenly_distributed, "show_captcha":show_captcha, "completion_code":str(uuid.uuid4()) }, "criterias":criterias, "time_created":datetime.now().strftime("%d/%m/%Y %H:%M:%S") };
            st.session_state.config = config;
            json.dump(config, open(os.path.join(".human_eval_config", "config.json"), "w"));
            models_responses_all = create_neccessary_file(data_sources, prompt_infos);
            question_pairs = get_question_pairs(models_responses_all);
            get_distribution(question_pairs, n_workers, n_questions_per_worker);
            st.toast("Created necessary files!");
            st.toast("Saved!");
        }
    } else {
        st.warning("Please upload at least one data source. or select one from the list if available.");
    }
}
