import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import json
import sys

def generate_heatmaps(workers_data, img_name):
    all_models = [
        "zephyr_7b-beta",
        "orca-mini_3b",
        "stablelm-zephyr_3b",
        "orca2_7b",
        "llama2_7b-chat",
        "openchat_7b-v3.5",
        "neural-chat_7b",
        "mistral_7b-instruct",
        "gpt-4",
        "starling-lm_7b",
        "vicuna_7b",
    ]

    criteria = ["clarity", "intelligence", "likability", "trustworthy", "overall"]

    model_performance = {
        model: {criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria}
        for model in all_models
    }
    preference_matrix = {
        criterion: {
            model: {other_model: 0 for other_model in all_models if other_model != model}
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
                result = response[crit]
                if result != "About the same":
                    winner, loser = (
                        (model1, model2) if result == "Response A" else (model2, model1)
                    )
                    preference_matrix[crit][winner][loser] += 1
                    model_performance[winner][crit]["wins"] += 1
                    model_performance[loser][crit]["losses"] += 1
                else:
                    model_performance[model1][crit]["ties"] += 1
                    model_performance[model2][crit]["ties"] += 1

    rows_list = []
    for model, crit_dict in model_performance.items():
        for crit, win_tie_loss in crit_dict.items():
            rows_list.append({"model": model, "criterion": crit, **win_tie_loss})

    df = pd.DataFrame(rows_list)
    pivot_wins = df.pivot_table(index="model", columns="criterion", values="wins")

    fig, axes = plt.subplots(3, 2, figsize=(14, 10))
    axes_flat = axes.flatten()
    individual_max = max(
        df[df["criterion"] == criterion]["wins"].max() for criterion in criteria
    )
    total_max = max(df[df["criterion"] == criterion]["wins"].max() +
        df[df["criterion"] == criterion]["ties"].max()
        + df[df["criterion"] == criterion]["losses"].max()
        for criterion in criteria
    )

    for i, criterion in enumerate(criteria):
        model_names = sorted(
            all_models, key=lambda x: -sum(preference_matrix[criterion][x].values())
        )
        heatmap_data = np.zeros((len(model_names), len(model_names)), dtype=int)
        for row, model1 in enumerate(model_names):
            for col, model2 in enumerate(model_names):
                if model1 != model2:
                    heatmap_data[row, col] = preference_matrix[criterion][model1][model2]
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
            vmax=individual_max,
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
    # plt.show()
    plt.savefig(f"heat_map_criterion_{img_name}.png")
def main(workers_data,img_name):
    generate_heatmaps(workers_data,img_name)

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) - 1 != 1:
        print("Usage: python heat_map_criteria.py <filename>")
        sys.exit(1)
    with open(sys.argv[1], "r") as file:
        workers_data = json.load(file)
    img_name = sys.argv[1].split("/")[-1].split(".")[0]
    main(workers_data,img_name)