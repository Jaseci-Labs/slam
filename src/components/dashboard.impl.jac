import:py streamlit as st;
import:py os;
import:py pandas as pd;
import:py numpy as np;
# import:py altair as alt;
import:py plotly.figure_factory as ff;
import:py plotly.express as px;
import:py json;
import:py datetime as dt;
import:jac from utils,  map_prompt_names_to_ids, generate_performance_data, format_responses_by_prompt;
import:jac from plot_utils, generate_stacked_bar_chart, generate_heatmaps;
import:py zipfile;
import:py shutil;

:can:<>init {
    if os.path.exists(os.path.join(".human_eval_config", "config.json")) {
        st.session_state.current_hv_config = json.load(open(os.path.join(".human_eval_config", "config.json")));
        if os.path.exists(os.path.join(".human_eval_config", "worker_count.txt")) {
            with open(os.path.join(".human_eval_config", "worker_count.txt"), "r") as f {st.session_state.current_worker_count = int(f.read());}
        } else {st.session_state.current_worker_count = 0;}
        st.session_state.workers_data_dir = os.path.abspath("results");
        st.session_state.distribution_file = os.path.abspath(os.path.join(".human_eval_config", "distribution.json"));
        st.session_state.response_file = os.path.abspath(os.path.join(".human_eval_config", "responses.json"));
        st.session_state.prompt_data_dir = os.path.abspath("data");
        st.session_state.prompt_info_file = os.path.abspath(os.path.join(".human_eval_config", "prompt_info.json"));
        st.session_state.models_responses = os.path.abspath(os.path.join(".human_eval_config", "models_responses.json"));
        with open(st.session_state.models_responses, "r") as f{
            data=json.load(f);
            st.session_state.active_list_of_models = list(data[next(iter(data))].keys());
        }
        if SELECTED_PROMPT_KEY not in st.session_state{st.session_state[SELECTED_PROMPT_KEY] = 'all_combined';}
    } else {st.error("Human Evaluation config was not found. Initialize a Human Evaluation first.");}

    if os.path.exists("results") and len(os.listdir("results")) > 0 {st.session_state.hv_results_files = os.listdir("results");}
    else {st.error("Results were not found. Initialize a Human Evaluation first. If Initiated already, wait until the results are ready.");}

    with st.form("upload_files_form", clear_on_submit=True) {
        uploaded_file = st.file_uploader("Upload the Output File");
        submitted = st.form_submit_button("Upload & Unzip");
        st.caption("CAUTION: This will overwrite the existing files. Please Makesure to have a backup.");
        if submitted and uploaded_file {
            shutil.rmtree("results", ignore_errors=True);
            shutil.rmtree(".human_eval_config", ignore_errors=True);
            shutil.rmtree("data", ignore_errors=True);
            with zipfile.ZipFile(uploaded_file, "r") as zip_ref {zip_ref.extractall(".");}
            st.rerun();
        }
    }
}

:can:status_indicator {
    (uptime_col, opened_col, full_output_col) = st.columns(3);

    eval_start_time = st.session_state.current_hv_config["time_created"];
    current_time = dt.datetime.now().strftime("%d/%m/%Y %H:%M:%S");
    time_diff = dt.datetime.strptime(current_time, "%d/%m/%Y %H:%M:%S") - dt.datetime.strptime(eval_start_time, "%d/%m/%Y %H:%M:%S");
    time_diff = f"{time_diff.days} days, {int(time_diff.seconds / 3600)} hours, {int(time_diff.seconds / 60) % 60} min";
    with uptime_col{with st.container(border=True) {st.metric("Human Evaluation Uptime", time_diff);}}

    n_workers = st.session_state.current_hv_config["config"]["n_workers"];
    with opened_col{with st.container(border=True) {st.metric("Number of Opens", f"{st.session_state.current_worker_count}/{n_workers}");}}

    with full_output_col{with st.container(border=True) {st.metric("Full Output", "Not Implemented");}}
}

:can:area_chart {
    chart_data = pd.DataFrame(np.random.randn(20, 3), columns=["a", "b", "c"]);
    st.area_chart(chart_data);
}

:can:bar_chart {
    chart_data = pd.DataFrame(np.random.randn(20, 3), columns=["a", "b", "c"]);
    st.bar_chart(chart_data);
}

:can:line_chart {
    chart_data = pd.DataFrame(np.random.randn(20, 3), columns=["a", "b", "c"]);
    st.line_chart(chart_data);
}

:can:altair_chart {
    chart_data = pd.DataFrame(np.random.randn(20, 3), columns=["a", "b", "c"]);
    c = alt.Chart(chart_data).mark_circle().encode(x="a", y="b", size="c", color="c", tooltip=["a", "b", "c"]);
    st.altair_chart(c, use_container_width=True);
}

:can:plotly_figure {
    criteria = None;
    eval_type = st.session_state.current_hv_config["hv_method"];
    if (eval_type == "A/B Testing") {
        criteria = ["overall"];
    }
    formatted_data = format_responses_by_prompt(st.session_state.workers_data_dir, st.session_state.distribution_file, st.session_state.response_file);
    normalize_df = pd.json_normalize(formatted_data, record_path=['responses'], meta=['prompt_id']);
    prompt_info = map_prompt_names_to_ids(st.session_state.prompt_data_dir,st.session_state.prompt_info_file);
    prompt_id_to_name = dict(zip(prompt_info.values(), prompt_info.keys()));

    normalize_df['prompt_name'] = normalize_df['prompt_id'].replace(prompt_id_to_name);
    normalize_df = normalize_df[normalize_df['time_taken'] <= 1000];
    data=[];
    labels=[];
    for (name, group) in normalize_df.groupby('prompt_name'){
        data.append(group['time_taken'].tolist());
        labels.append(name);
    }
    fig = ff.create_distplot(
        data, labels, 
        bin_size=.2,
        show_hist=True, show_rug=False,
        histnorm='probability density'
    );
    fig.update_layout(
        title_text='Distribution of Seconds-per-Comparison by Prompt',
        xaxis_title_text='Time Taken (seconds)',
        yaxis_title_text='Density'
    );
    st.plotly_chart(fig, use_container_width=True);
}


:can:plotly_histogram {
    criteria = None;
    eval_type = st.session_state.current_hv_config["hv_method"];
    if (eval_type == "A/B Testing") {
        criteria = ["overall"];
    }
    formatted_data = format_responses_by_prompt(st.session_state.workers_data_dir, st.session_state.distribution_file, st.session_state.response_file);
    normalize_df = pd.json_normalize(formatted_data, record_path=['responses'], meta=['prompt_id']);
    prompt_info = map_prompt_names_to_ids(st.session_state.prompt_data_dir,st.session_state.prompt_info_file);
    prompt_id_to_name = dict(zip(prompt_info.values(), prompt_info.keys()));

    normalize_df['prompt_name'] = normalize_df['prompt_id'].replace(prompt_id_to_name);
    normalize_df = normalize_df[normalize_df['time_taken'] <= 1000];
    fig = px.histogram(
        normalize_df, 
        x='time_taken', 
        color='prompt_name',
        barmode='overlay', 
        nbins=30,
        histnorm='probability density'
    );

    fig.update_layout(
        title_text='Histogram of Seconds-per-Comparison by Prompt', 
        xaxis_title_text='Time Taken (seconds)',
        yaxis_title_text='Density', 
        bargap=0.1,  
        bargroupgap=0.1
    );

    st.plotly_chart(fig, use_container_width=True);

}

:can:heat_map(workers_data_dir:str = None, eval_type:str = None, placeholder:str = None, selected_prompt:str = None) {
    criteria = None;
    selected_prompt_id = st.session_state[SELECTED_PROMPT_KEY];
    if not workers_data_dir {workers_data_dir = st.session_state.workers_data_dir;}
    if not eval_type {
        eval_type = st.session_state.current_hv_config["hv_method"];
    }
    if (eval_type == "A/B Testing") {
        criteria = ["overall"];
    }

    formatted_data = format_responses_by_prompt(workers_data_dir, st.session_state.distribution_file, st.session_state.response_file);
    prompt_info = map_prompt_names_to_ids(st.session_state.prompt_data_dir,st.session_state.prompt_info_file);
    prompt_ids = list(prompt_info.keys());
    prompt_ids.insert(0, "all_combined");
    if not selected_prompt{
        new_prompt_index = prompt_ids.index(selected_prompt_id);
        user_selected_prompt = st.selectbox("Select Prompt:", prompt_ids, index=new_prompt_index);
        if st.session_state[SELECTED_PROMPT_KEY] != user_selected_prompt{st.session_state[SELECTED_PROMPT_KEY] = user_selected_prompt;}
    } else { 
        st.session_state[SELECTED_PROMPT_KEY] = selected_prompt;
        user_selected_prompt  = selected_prompt;
    }

    if user_selected_prompt != "all_combined" {

        (model_performance, preference_matrix, criteria)=generate_performance_data(formatted_data,st.session_state.active_list_of_models, prompt_info[user_selected_prompt],criteria);
        generate_heatmaps(placeholder, model_performance, preference_matrix, st.session_state.active_list_of_models, criteria);
    } else {
        (model_performance, preference_matrix, criteria)=generate_performance_data(formatted_data,st.session_state.active_list_of_models, user_selected_prompt, criteria);
        generate_heatmaps(placeholder, model_performance, preference_matrix,st.session_state.active_list_of_models, criteria);
    }
}

:can:stacked_bar_chart {
    criteria = None;
    eval_type = st.session_state.current_hv_config["hv_method"];
    if (eval_type == "A/B Testing") {
        criteria = ["overall"];
    }
    
    formatted_data = format_responses_by_prompt(st.session_state.workers_data_dir, st.session_state.distribution_file, st.session_state.response_file);
    prompt_info = map_prompt_names_to_ids(st.session_state.prompt_data_dir,st.session_state.prompt_info_file);
    prompt_ids = list(prompt_info.keys());
    prompt_ids.insert(0, "all_combined");
    selected_prompt_id = st.selectbox("Select Prompt:", prompt_ids);
    if selected_prompt_id != "all_combined" {
        (model_performance, preference_matrix, criteria)=generate_performance_data(formatted_data, st.session_state.active_list_of_models,prompt_info[selected_prompt_id], criteria);
        generate_stacked_bar_chart(model_performance, criteria);
    } else {
        (model_performance, preference_matrix, criteria)=generate_performance_data(formatted_data,st.session_state.active_list_of_models, selected_prompt_id, criteria);
        generate_stacked_bar_chart(model_performance, criteria);
    }
}