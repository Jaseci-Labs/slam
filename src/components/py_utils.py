import os
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import json
import streamlit as st


def generate_stacked_bar_chart(formatted_output, all_models, prompt_id, criteria=None):
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
        # Check if we're looking at a specific prompt_id or all data
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
                    else:
                        model_performance[model1][crit]["ties"] += 1
                        model_performance[model2][crit]["ties"] += 1

    def add_value_labels(ax, bars):
        for bar in bars:
            height = bar.get_height()
            label_position = bar.get_y() + height / 2
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                label_position,
                f"{int(height)}",
                ha="center",
                va="center",
                color="black",
                fontsize=8,
            )

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
    if len(criteria) > 1:
        fig, axes = plt.subplots(2, 3, figsize=(12, 8), sharey=True)

    else:
        fig, axes = plt.subplots(1, 1, figsize=(8, 4), sharey=True)
        axes = axes
    bar_colors = ["#228B22", "#DAA520", "#B22222"]

    for i, criterion in enumerate(criteria):
        if len(criteria) > 1:
            row = i // 3
            col = i % 3
            ax = axes[row, col]
            if i == 5:
                fig.delaxes(axes[row, col])
                continue
        else:
            ax = axes
        crit_df = df[df["criterion"] == criterion].sort_values("wins", ascending=False)
        models = crit_df["model"]
        wins = ax.bar(models, crit_df["wins"], label="Wins", color=bar_colors[0])
        ties = ax.bar(
            models,
            crit_df["ties"],
            bottom=crit_df["wins"],
            label="Ties",
            color=bar_colors[1],
        )
        losses = ax.bar(
            models,
            crit_df["losses"],
            bottom=crit_df["wins"] + crit_df["ties"],
            label="Losses",
            color=bar_colors[2],
        )
        add_value_labels(ax, wins)
        add_value_labels(ax, ties)
        add_value_labels(ax, losses)

        ax.set_title(f"{criterion.capitalize()} - Wins, Ties, and Losses by Model")
        ax.set_xlabel("Models")
        ax.set_ylabel("Counts")
        ax.set_xticklabels(models, rotation=45, ha="right")
        ax.grid(axis="y")
    if len(criteria) > 1:
        handles, labels = axes[0, 0].get_legend_handles_labels()
        fig.legend(handles, labels, loc="upper center", ncol=3)
    else:
        fig.legend(loc="upper center", ncol=3)
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    st.pyplot(plt)


def generate_heatmaps(formatted_output, all_models, prompt_id, criteria=None):
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
        # Check if we're looking at a specific prompt_id or all data
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
                    else:
                        model_performance[model1][crit]["ties"] += 1
                        model_performance[model2][crit]["ties"] += 1
    rows_list = []
    for model, crit_dict in model_performance.items():
        for crit, win_tie_loss in crit_dict.items():
            rows_list.append({"model": model, "criterion": crit, **win_tie_loss})

    df = pd.DataFrame(rows_list)
    pivot_wins = df.pivot_table(index="model", columns="criterion", values="wins")
    if len(criteria) > 1:
        fig, axes = plt.subplots(3, 2, figsize=(14, 10))
        axes_flat = axes.flatten()
    else:
        fig, axes = plt.subplots(1, 1, figsize=(8, 4))
        axes_flat = [axes]
    global_individual_max = 0
    for criterion in criteria:
        for model in all_models:
            max_wins = max(preference_matrix[criterion][model].values())
            global_individual_max = max(global_individual_max, max_wins)
    total_max = df[["wins", "ties", "losses"]].max().max()
    for i, criterion in enumerate(criteria):
        model_names = sorted(
            all_models, key=lambda x: -sum(preference_matrix[criterion][x].values())
        )
        heatmap_data = np.zeros((len(model_names), len(model_names)), dtype=int)
        for row, model1 in enumerate(model_names):
            for col, model2 in enumerate(model_names):
                if model1 != model2:
                    heatmap_data[row, col] = preference_matrix[criterion][model1][
                        model2
                    ]
        sorted_wins = pivot_wins.loc[model_names, criterion]
        mask = np.eye(len(model_names), dtype=bool)
        sns.heatmap(
            heatmap_data,
            mask=mask,
            annot=True,
            fmt="d",
            cmap="YlGnBu",
            xticklabels=model_names,
            yticklabels=model_names,
            ax=axes_flat[i],
            cbar=True,
            vmax=global_individual_max,
            cbar_kws={"label": "Individual Wins"},
        )
        for j, model in enumerate(model_names):
            heatmap_data[j, j] = sorted_wins[j]
        sns.heatmap(
            heatmap_data,
            mask=~mask,
            annot=True,
            fmt="d",
            cmap="BuPu",
            xticklabels=model_names,
            yticklabels=model_names,
            ax=axes_flat[i],
            cbar=True,
            vmax=total_max,
            cbar_kws={"label": "Total Wins"},
        )
        axes_flat[i].set_title(f"Heatmap of Wins for {criterion}")

    plt.tight_layout()
    st.pyplot(plt)


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
    json_df = pd.json_normalize(formatted_data, record_path=['responses'], meta=['prompt_id'])
    df_input = json_df.copy()
    df_pairs = pd.concat([
    df_input[['model_a', 'model_b', 'time_taken']].rename(columns={'model_a': 'model_1', 'model_b': 'model_2'}),
    df_input[['model_b', 'model_a', 'time_taken']].rename(columns={'model_b': 'model_1', 'model_a': 'model_2'})
    ])
    df_grouped = df_pairs.groupby(['model_1', 'model_2'], as_index=False).agg({'time_taken': 'mean'})
    pivot_table = df_grouped.pivot(index='model_1', columns='model_2', values='time_taken')

    plt.figure(figsize=(10, 8))
    sns.heatmap(pivot_table, annot=True, cmap='viridis', fmt=".2f")
    plt.title('Heatmap of Time Taken Between Model Pairs')
    st.pyplot(plt)