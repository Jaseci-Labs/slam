import:py pandas as pd;
import:py streamlit as st;
import from utils {map_prompt_names_to_ids, format_responses_by_prompt}

can model_win_percentage_table {
    if st.session_state.get("current_hv_config", None) {
        criteria = ["overall"];
        model_performance = {model: {"wins": 0, "total": 0}  for model in st.session_state.active_list_of_models};
        formatted_data = format_responses_by_prompt(st.session_state.workers_data_dir, st.session_state.distribution_file, st.session_state.response_file);
        prompt_info = map_prompt_names_to_ids(st.session_state.prompt_data_dir, st.session_state.prompt_info_file);
        prompt_ids = list(prompt_info.keys());
        prompt_ids.insert(0, "all_combined");
        user_selected_prompt = st.selectbox("Select Prompt:", prompt_ids, key="select_box_win");
        if user_selected_prompt != "all_combined" {
            user_selected_prompt = prompt_info[user_selected_prompt];
        }
        for outputs in formatted_data {
            if user_selected_prompt == "all_combined"
                or outputs["prompt_id"] == user_selected_prompt {
                for response in outputs["responses"] {
                    model1 = response["model_a"];
                    model2 = response["model_b"];
                    result = response.get("overall");
                    if result == "Response A" {
                        model_performance[model1]["wins"]+=1;
                    } elif result == "Response B" {
                        model_performance[model2]["wins"]+=1;
                    }
                    model_performance[model1]["total"]+=1;
                    model_performance[model2]["total"]+=1;
                }
            }
        }
        data = [];
        for (model, counts) in model_performance.items() {
            win_percentage = (counts["wins"] / counts["total"]) if counts["total"] else 0;
            data.append({"Model": model, "Win Percentage": win_percentage});
        }
        df = pd.DataFrame(data);
        df = df.sort_values(by='Win Percentage', ascending=False);
        df['Rank'] = range(1, len(df) + 1);
        df = df[['Rank', 'Model', 'Win Percentage']];
        (col1, col2, col3) = st.columns([1, 2, 1]);
        with col2 {
            st.dataframe(df.set_index('Rank'), width=430, height=435);
        }
    } else {
        st.error("Human Evaluation config was not found. Initialize a Human Evaluation first.");
    }
}
