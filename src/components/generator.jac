import:py streamlit as st;

import:jac from utils, check_engine_status;

can <>init;
can model_settings;
can prompt_settings;
can generate_responses(selected_models: list, n_samples: int, temp: float, prompt_template: str, arguments: dict);

can generator {
    <>init();
    st.header('Response Generator');
    st.caption("This helps you to generate the necessary response for the given prompttemplate with given values for all the selected SLMs and propierity LLMs.");

    engine_status = check_engine_status();
    (selected_models, n_samples, temp) = model_settings();
    (prompt_template, arguments) = prompt_settings();
    
    if len(selected_models) > 0 and prompt_template and all([x for x in arguments.values()]) and engine_status {
        st.caption('Click the button below to generate the responses. This may take a while.');
        if st.button('Generate Responses') {
            generate_responses(selected_models, n_samples, temp, prompt_template, arguments);
        }
    } else {
        st.error('Please select at least one model, fill all the arguments in the prompt template and make sure the query engine is running.');
    }
}