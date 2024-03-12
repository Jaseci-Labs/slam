import:py streamlit as st;

can <>init;
can status_indicator;
can area_chart;
can bar_chart;
can line_chart;
can altair_chart;
can plotly_figure;
can heat_map(workers_data_dir:str = None, eval_type:str = None, placeholder:str = None, selected_prompt:str = None);
can stacked_bar_chart;
can plotly_histogram;

glob SELECTED_PROMPT_KEY = 'selected_prompt';

can dashboard {
    if st.session_state.get("current_hv_config", None){
        status_indicator();
        # chart_type = st.selectbox("Select a chart type:", ("Area Chart", "Bar Chart", "Line Chart", "Altair Chart", "Plotly Figure", "Heat Map","Stacked Bar Chart","Histogram"));
        chart_type = st.selectbox("Select a chart type:", ("Disribution Plot", "Heat Map","Stacked Bar Chart","Histogram"));
        # Conditional rendering based on the dropdown selection
        if chart_type == "Area Chart"{area_chart();}
        elif chart_type == "Bar Chart"{bar_chart();}
        elif chart_type == "Line Chart"{line_chart();}
        elif chart_type == "Altair Chart"{altair_chart();}
        elif chart_type == "Disribution Plot"{plotly_figure();}
        elif chart_type == "Heat Map"{
            if 'button_clicked' in st.session_state{st.session_state.button_clicked = False;}
            heat_map();
            }
        elif chart_type == "Stacked Bar Chart"{stacked_bar_chart();}
        elif chart_type == "Histogram"{plotly_histogram();}
    } else {
        <>init();
    }
    if st.button("Refresh") {
        <>init();
        st.rerun();
    }
}
