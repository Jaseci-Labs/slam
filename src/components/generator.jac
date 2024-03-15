import:py streamlit as st;

can <>init;
can model_settings;
can prompt_settings;
can check_engine_status;
can generate_responses(selected_models: list, n_samples: int, temp: float, prompt_template: str, arguments: dict);

can generator {
    if "generator_init" not in st.session_state {<>init();}
    st.header('Response Generator');
    st.caption("This helps you to generate the necessary response for the "
    "given prompttemplate with given values for all the selected SLMs and "
    "propierity LLMs.");

    (selected_models, n_samples, temp) = model_settings();
    (prompt_template, arguments) = prompt_settings();
    if st.session_state.engine_status {
        if len(selected_models) > 0 and prompt_template and all([x for x in arguments.values()]) {
            st.caption('Click the button below to generate the responses. This may take a while.');
            if st.button('Generate Responses') {
                generate_responses(selected_models, n_samples, temp, prompt_template, arguments);
                convert_run(st.session_state['run_id']);
                st.success('Responses generated and data is ready for human evaluation!');
            }
        } else {st.error('Make sure every field is filled properly');}
    } else {
        st.error('Please make sure the query engine is running.');
    }
    
    if st.button("Refresh", key="generator_refresh_btn") {<>init();}
}