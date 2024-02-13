import os
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import json
import streamlit as st


def generate_heatmaps(workers_data, all_models, criteria=None):
    if not criteria:
        criteria = ["clarity", "intelligence", "likability", "trustworthy", "overall"]

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
    for worker_responses in workers_data:
        worker_key = list(worker_responses.keys())[0]
        for response in worker_responses[worker_key]:
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


def format_responses(workers_data_dir, distribution_file, response_file, criteria_set):
    out_dataset = []
    if not criteria_set:
        criteria_set = [
            "clarity",
            "intelligence",
            "likability",
            "trustworthy",
            "overall",
        ]

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
            except:
                print(file_path)
                continue
            if "question_index" in worker_data and worker_data["question_index"] == 10:
                curr_distribution_set = distribution.get(
                    worker_data["question_set_id"], None
                )
                if curr_distribution_set is not None:
                    curr_worker_data_set = []
                    for i, (curr_dist, curr_worker_data) in enumerate(
                        zip(curr_distribution_set, worker_data["evals"])
                    ):
                        model_a, response_a_id = curr_dist[1][0], curr_dist[2][0]
                        model_b, response_b_id = curr_dist[1][1], curr_dist[2][1]
                        response_a = all_responses.get(response_a_id, None)
                        response_b = all_responses.get(response_b_id, None)
                        criteria_data = [
                            {
                                criteria_set[i]: curr_worker_data["result"][i]
                                for i in range(len(criteria_set))
                            }
                        ]
                        curr_resp_contruct = {
                            "model_a": model_a,
                            "response_a": response_a,
                            "model_b": model_b,
                            "response_b": response_b,
                        }
                        curr_resp_contruct.update(criteria_data[0])
                        if i == 0:
                            start_time = datetime.fromtimestamp(
                                worker_data["start_time"]
                            )
                        end_time = datetime.fromtimestamp(curr_worker_data["time"])
                        curr_resp_contruct.update(
                            {"time_taken": (end_time - start_time).total_seconds()}
                        )
                        start_time = end_time
                        curr_worker_data_set.append(curr_resp_contruct)
                    out_dataset.append({worker_data["worker_id"]: curr_worker_data_set})
    return out_dataset


def generate_stacked_bar_chart(workers_data, all_models, criteria=None):
    if not criteria:
        criteria = ["clarity", "intelligence", "likability", "trustworthy", "overall"]
    model_performance = {
        model: {
            criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria
        }
        for model in all_models
    }

    # Fill the performance matrix with the data
    for worker_responses in workers_data:
        worker_key = list(worker_responses.keys())[0]
        for response in worker_responses[worker_key]:
            model1 = response["model_a"]
            model2 = response["model_b"]
            for crit in criteria:
                result = response.get(crit)
                if result == "Response A":
                    model_performance[model1][crit]["wins"] += 1
                    model_performance[model2][crit]["losses"] += 1
                elif result == "Response B":
                    model_performance[model1][crit]["losses"] += 1
                    model_performance[model2][crit]["wins"] += 1
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
