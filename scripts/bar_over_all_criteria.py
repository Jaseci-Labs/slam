import matplotlib.pyplot as plt
import pandas as pd
import json
import sys

if len(sys.argv) - 1 != 1:
    print("Usage: python bar_over_all_criteria.py <filename>")
    exit(1)
file_name = sys.argv[1]
img_name = file_name.split("/")[-1].split(".")[0]

# all the models considered for the evaluation
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

with open(file_name, "r") as file:
    workers_data = json.load(file)

criteria = ["clarity", "intelligence", "likability", "trustworthy"]


# Initialize the performance matrix with zero counts
model_performance = {
    model: {criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria}
    for model in all_models
}

# Fill the performance matrix with the data
for worker_responses in workers_data:
    worker_key = list(worker_responses.keys())[0]
    for response in worker_responses[worker_key]:
        model1 = response["model1"]
        model2 = response["model2"]
        for crit in criteria:
            result = response.get(crit)
            if result == "1 is better":
                model_performance[model1][crit]["wins"] += 1
                model_performance[model2][crit]["losses"] += 1
            elif result == "2 is better":
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
# Determine the global minimum and maximum across all models and criteria for wins, ties, and losses
global_min = df[["wins", "ties", "losses"]].min().min()
global_max = df[["wins", "ties", "losses"]].max().max()

# Plotting with common color bar scale
fig, axes = plt.subplots(2, 2, figsize=(12, 8), sharey=True)
axes = axes.flatten()

# Define colors for each bar segment
colors = ["#228B22", "#DAA520", "#B22222"]

for i, criterion in enumerate(criteria):
    ax = axes[i]
    crit_df = df[df["criterion"] == criterion].sort_values("wins", ascending=False)
    models = crit_df["model"]

    # Plot each stack segment
    wins = ax.bar(models, crit_df["wins"], label="Wins", color=colors[0])
    ties = ax.bar(
        models, crit_df["ties"], bottom=crit_df["wins"], label="Ties", color=colors[1]
    )
    losses = ax.bar(
        models,
        crit_df["losses"],
        bottom=crit_df["wins"] + crit_df["ties"],
        label="Losses",
        color=colors[2],
    )

    # Add value labels to each bar segment
    add_value_labels(ax, wins)
    add_value_labels(ax, ties)
    add_value_labels(ax, losses)

    ax.set_title(f"{criterion.capitalize()} - Wins, Ties, and Losses by Model")
    ax.set_xlabel("Models")
    ax.set_ylabel("Counts")
    ax.set_xticklabels(models, rotation=45, ha="right")
    ax.grid(axis="y")

    # Normalize the color of the bars to the global min and max
    for bar, color in zip([wins, ties, losses], colors):
        for patch in bar.patches:
            patch.set_color(
                plt.cm.viridis(
                    (patch.get_height() - global_min) / (global_max - global_min)
                )
            )

handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", ncol=3)

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.savefig(f"stacked_bar_criterion_{img_name}.png")
