'''Evaluation Setup'''
import:py from datetime, datetime;
import:py json;
import:py os;
import:py shutil;
import:py streamlit as st;
import:py uuid;

'''Sanity Check for the Human Evaluation Setup'''
can sanity_check(n_models: int, n_usecases: int, n_workers: int, n_questions_per_worker: int);

'''Get the Question Pairs for each distribution'''
can get_question_pairs(models_responses_all: dict);

'''Get the Distribution of the Questions for the Workers'''
can get_distribution(question_pairs: list, n_workers: int, n_questions_per_worker: int);

'''Initializing the Setup Config.'''
can <>init;

'''Evaluation Method Selection View'''
can hv_evaluation_method_selector;

'''Evaluation Configurator'''
can hv_configurator;

'''Retrieve Prompt Information from the datasources show in a Editable View'''
can get_prompt_info(data_sources: list) -> dict;

'''Add Data Sources to the Configurator'''
can add_data_sources;

'''Create Necessary Files for the Evaluation'''
can create_neccessary_file(data_sources: list, _prompt_infos: dict);

'''Evaluation Setup Component'''
can setup {
    <>init();
    st.header("Evaluation Setup");
    st.caption("This setup will help you to configure the evaluation configuration for both human and auto evaluation.");
    with st.container(border=True) {
        (hv_method, criterias) = hv_evaluation_method_selector();
    }
    with st.container(border=True) {
        (n_workers, ability_to_tie, data_sources, n_questions_per_worker, evenly_distributed, show_captcha) = hv_configurator();
        add_data_sources();
    }
    if data_sources {
        prompt_infos = get_prompt_info(data_sources);
        if st.button("Create Evaluation Configuration") {
            try {
                os.makedirs(".human_eval_config", exist_ok=True);

                assert not evenly_distributed or n_questions_per_worker % len(data_sources) == 0, "Number of questions per worker should be divisible by the number of Usecases for an evenly distributed evaluation.";

                config = {"hv_method": hv_method, "config": {"n_workers": n_workers, "n_questions_per_worker": n_questions_per_worker, "ability_to_tie": ability_to_tie, "data_sources": data_sources, "evenly_distributed": evenly_distributed, "show_captcha": show_captcha, "completion_code": str(uuid.uuid4())}, "criterias": criterias, "time_created": datetime.now().strftime("%d/%m/%Y %H:%M:%S")};
                st.session_state.config = config;

                models_responses_all = create_neccessary_file(data_sources, prompt_infos);
                question_pairs = get_question_pairs(models_responses_all);
                distribution = get_distribution(question_pairs, n_workers, n_questions_per_worker);

                json.dump(config, open(os.path.join(".human_eval_config", "config.json"), "w"));
                json.dump(config, open(os.path.join(".human_eval_config", "config.bak.json"), "w"));
                json.dump(question_pairs, open(os.path.join(".human_eval_config", "unique_question_pairs.json"), "w"), indent=2);
                json.dump(distribution, open(os.path.join(".human_eval_config", "distribution.json"), "w"), indent=2);
                json.dump(distribution, open(os.path.join(".human_eval_config", "distribution.bak.json"), "w"), indent=2);

                st.toast("Created necessary files!");
                st.toast("Human Evaluation is Initialized!");
            } except Exception as e {
                st.error(str(e));
                shutil.rmtree(".human_eval_config");
            }
        }
    } else {
        st.warning("Please upload at least one data source. or select one from the list if available.");
    }
}