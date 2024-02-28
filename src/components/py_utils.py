import os
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import json
import streamlit as st
from plotly.subplots import make_subplots
import plotly.graph_objects as go


def generate_performance_data(formatted_output, all_models, prompt_id, criteria=None):
    if not criteria:
        criteria = [
            "overall",
            "clarity",
            "intelligence",
            "likability",
            "trustworthiness",
        ]

    model_performance = {
        model: {
            criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria
        }
        for model in all_models
    }
    preference_matrix = {
        criterion: {
            model: {
                other_model: 0 for other_model in all_models if other_model != model
            }
            for model in all_models
        }
        for criterion in criteria
    }
    for outputs in formatted_output:
        if prompt_id == "all_combined" or outputs["prompt_id"] == prompt_id:
            for response in outputs["responses"]:
                model1 = response["model_a"]
                model2 = response["model_b"]
                for crit in criteria:
                    result = response.get(crit)
                    if result == "Response A":
                        model_performance[model1][crit]["wins"] += 1
                        model_performance[model2][crit]["losses"] += 1
                        preference_matrix[crit][model1][model2] += 1
                    elif result == "Response B":
                        model_performance[model1][crit]["losses"] += 1
                        model_performance[model2][crit]["wins"] += 1
                        preference_matrix[crit][model2][model1] += 1
                    else:  # Ties
                        model_performance[model1][crit]["ties"] += 1
                        model_performance[model2][crit]["ties"] += 1

    return model_performance, preference_matrix, criteria


def generate_plot_stacked_bar_chart(model_performance, criteria):
    df_data = []
    for model, crits in model_performance.items():
        for crit, counts in crits.items():
            df_data.append(
                {
                    "model": model,
                    "criterion": crit,
                    "wins": counts["wins"],
                    "ties": counts["ties"],
                    "losses": counts["losses"],
                }
            )

    df = pd.DataFrame(df_data)
    fig = make_subplots(
        rows=len(criteria), cols=1, shared_xaxes=False, vertical_spacing=0.02
    )
    fig_height_per_row = 200
    total_fig_height = fig_height_per_row * len(criteria)
    colors = {"wins": "green", "ties": "orange", "losses": "red"}
    for i, criterion in enumerate(criteria):
        criterion_data = df[df["criterion"] == criterion].sort_values(
            "wins", ascending=False
        )
        for j, outcome in enumerate(["wins", "ties", "losses"]):
            fig.add_trace(
                go.Bar(
                    x=criterion_data["model"],
                    y=criterion_data[outcome],
                    text=criterion_data[outcome],  # Set the text to the y-values
                    textposition="auto",
                    name=outcome.capitalize(),
                    marker_color=colors[outcome],
                    showlegend=(i == 2),
                ),
                row=i + 1,
                col=1,
            )
    fig.update_layout(
        barmode="stack",
        title="Model Performance by Criterion",
        height=total_fig_height,
    )
    for i, criterion in enumerate(criteria):
        fig.update_yaxes(
            title_text=criterion.capitalize(),
            row=i + 1,
            col=1,
            title_standoff=25,
        )
    st.plotly_chart(fig, use_container_width=True)


def generate_heatmaps(
    placeholder, model_performance, preference_matrix, all_models, criteria
):
    rows_list = []
    for model, crit_dict in model_performance.items():
        for crit, win_tie_loss in crit_dict.items():
            rows_list.append({"model": model, "criterion": crit, **win_tie_loss})
    df = pd.DataFrame(rows_list)
    global_max = df[["wins", "ties", "losses"]].max().max()
    global_min = df[["wins", "ties", "losses"]].min().max()
    subplot_titles = []
    for crit in criteria:
        subplot_titles.append(f"Heatmap of Wins for {crit}")  # Left column title
        subplot_titles.append(f"Heatmap of Total Wins for {crit}")  # Right column title
    fig = make_subplots(
        rows=len(criteria),
        cols=2,
        subplot_titles=subplot_titles,
        horizontal_spacing=0.15,
        specs=[[{}, {}] for _ in range(len(criteria))],
    )

    global_individual_max = 0
    for criterion in criteria:
        for model in all_models:
            max_wins = max(preference_matrix[criterion][model].values())
            global_individual_max = max(global_individual_max, max_wins)
    for i, criterion in enumerate(criteria):
        sorted_models = sorted(
            all_models,
            key=lambda model: -sum(preference_matrix[criterion][model].values()),
        )
        heatmap_data = np.zeros((len(sorted_models), len(sorted_models)), dtype=int)
        for row, model1 in enumerate(sorted_models):
            for col, model2 in enumerate(sorted_models):
                if model1 != model2:
                    heatmap_data[row, col] = preference_matrix[criterion][model1].get(
                        model2, 0
                    )
        text = [[str(value) for value in row] for row in heatmap_data]
        fig.add_trace(
            go.Heatmap(
                z=heatmap_data[::-1],
                x=sorted_models,
                y=list(reversed(sorted_models)),
                colorscale="YlGnBu",
                zmin=0,
                zmax=global_individual_max,
                text=list(reversed(text)),
                texttemplate="%{text}",
                colorbar=dict(
                    title="Individual Wins",
                    len=0.25,
                    y=(0.85 * (1 - (i / len(criteria)))),
                    yanchor="bottom",
                    x=1.1,  # Position the color bar to the right of the heatmaps
                ),
                showscale=(i == 2),
            ),
            row=i + 1,
            col=1,
        )
        total_wins_data = np.array([[wins] for wins in heatmap_data.sum(axis=1)])
        fig.add_trace(
            go.Heatmap(
                z=total_wins_data[::-1],
                x=["Total Wins"],
                y=list(reversed(sorted_models)),
                colorscale="BuPu",
                zmin=global_min,
                zmax=global_max,
                text=list(reversed(total_wins_data)),
                texttemplate="%{text}",
                colorbar=dict(
                    title="Total Wins",
                    len=0.25,
                    y=(0.85 * (1 - (i / len(criteria)))),  # Adjust this value as needed
                    yanchor="bottom",
                    x=1.1 + 0.10,
                ),
                showscale=(i == 2),
            ),
            row=i + 1,
            col=2,
        )

    fig.update_layout(
        title_text="Model Performance by Criterion",
        height=350 * len(criteria),
        width=1200,
    )

    if placeholder:
        with placeholder.container():
            st.plotly_chart(fig, use_container_width=True)
    else:
        st.plotly_chart(fig, use_container_width=True)


def format_responses_by_prompt(workers_data_dir, distribution_file, response_file):
    out_dataset = {}

    with open(distribution_file, "r") as file:
        distribution = json.load(file)
    with open(response_file, "r") as file:
        all_responses = json.load(file)
    for filename in os.listdir(workers_data_dir):
        file_path = os.path.join(workers_data_dir, filename)
        if os.path.isfile(file_path):
            try:
                with open(file_path, "r") as file:
                    worker_data = json.load(file)
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
                continue
            if "question_index" in worker_data and worker_data["question_index"] == 10:
                curr_distribution_set = distribution.get(
                    worker_data["question_set_id"], None
                )
                if curr_distribution_set is not None:
                    for i, curr_worker_data in enumerate(worker_data["evals"]):
                        curr_set = curr_worker_data.get("question")
                        prompt_id = curr_set[0]
                        model_names = list(curr_set[1].keys())
                        model_a, response_a_id = (
                            model_names[0],
                            curr_set[1][model_names[0]],
                        )
                        model_b, response_b_id = (
                            model_names[1],
                            curr_set[1][model_names[1]],
                        )
                        response_a = all_responses.get(response_a_id, None)
                        response_b = all_responses.get(response_b_id, None)

                        curr_resp_contruct = {
                            "model_a": model_a,
                            "response_a": response_a,
                            "model_b": model_b,
                            "response_b": response_b,
                            "worker_id": worker_data["worker_id"],
                        }
                        curr_resp_contruct.update(curr_worker_data["result"])
                        if i == 0:
                            start_time = datetime.fromtimestamp(
                                worker_data["start_time"]
                            )
                        end_time = datetime.fromtimestamp(curr_worker_data["time"])
                        curr_resp_contruct.update(
                            {"time_taken": (end_time - start_time).total_seconds()}
                        )
                        start_time = end_time
                        if prompt_id not in out_dataset:
                            out_dataset[prompt_id] = []
                        out_dataset[prompt_id].append(curr_resp_contruct)

    # Convert to list of dicts with prompt_id as a key for each entry, if needed
    formatted_output = [
        {"prompt_id": prompt_id, "responses": responses}
        for prompt_id, responses in out_dataset.items()
    ]
    return formatted_output


def get_unique_prompt_ids(prompt_data_dir, prompt_info_file):
    """
    Returns a list of unique prompt ids
    """

    with open(prompt_info_file, "r") as file:
        prompt_info = json.load(file)
    prompt_info = [{prompt["prompt_id"]: prompt["prompt"]} for prompt in prompt_info]
    prompt_ids = {}
    for filename in os.listdir(prompt_data_dir):
        use_case_name = "_".join(filename.split(".")[0].split("_")[:-1])
        file_path = os.path.join(prompt_data_dir, filename)
        with open(file_path, "r") as file:
            prompt_data = json.load(file)["prompt"]
            for inv_prompt in prompt_info:
                if prompt_data == list(inv_prompt.values())[0]:
                    prompt_ids[use_case_name] = list(inv_prompt.keys())[0]
    return prompt_ids


def generate_heatmap_time(formatted_data):
    json_df = pd.json_normalize(
        formatted_data, record_path=["responses"], meta=["prompt_id"]
    )
    df_input = json_df.copy()
    df_pairs = pd.concat(
        [
            df_input[["model_a", "model_b", "time_taken"]].rename(
                columns={"model_a": "model_1", "model_b": "model_2"}
            ),
            df_input[["model_b", "model_a", "time_taken"]].rename(
                columns={"model_b": "model_1", "model_a": "model_2"}
            ),
        ]
    )
    df_grouped = df_pairs.groupby(["model_1", "model_2"], as_index=False).agg(
        {"time_taken": "mean"}
    )
    pivot_table = df_grouped.pivot(
        index="model_1", columns="model_2", values="time_taken"
    )

    plt.figure(figsize=(10, 8))
    sns.heatmap(pivot_table, annot=True, cmap="viridis", fmt=".2f")
    plt.title("Heatmap of Time Taken Between Model Pairs")
    st.pyplot(plt)
