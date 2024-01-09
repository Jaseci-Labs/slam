include:jac components.utils;
include:jac components.theme;
import:py re;


can main {
    st.header('Response Generator');
    st.caption("This helps you to generate the necessary response for the given prompt template with given values for all the selected SLMs and propierity LLMs.");
    
    st.subheader('Model Settings');
    (model_select_col, n_samples_col, engine_status_col) = st.columns(3);
    selected_models = model_select_col.multiselect('Select Models', ['A', 'B', 'C']);
    n_samples = n_samples_col.number_input('Number of Samples', 1, 100, 1);
    engine_status_col.success('Query Engine is running');

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
                with st.spinner(f"Generating responses for model {model}...") {
                    time.sleep(5);
                }
            }
        }
    }
}