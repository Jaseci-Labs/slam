import:py streamlit as st;
import:py os;
import:py pandas as pd;
import:py numpy as np;
import from plotly.subplots {make_subplots}
import:py plotly.graph_objects as go;
import:py json;

can generate_stacked_bar_chart(model_performance: dict, criteria: list) {
    df_data = [];
    
    for (model, crits) in model_performance.items() {
        for (crit, counts) in crits.items() {
            df_data.append({"model": model, "criterion": crit, "wins": counts["wins"], "ties": counts["ties"], "losses": counts["losses"]});
        }
    }
    df = pd.DataFrame(df_data);
    fig = make_subplots(rows=len(criteria), cols=1, shared_xaxes=False, vertical_spacing=0.02);
    if len(criteria) == 1 {
        fig_height_per_row = 300;
    } else {
        fig_height_per_row = 220;
    }
    total_fig_height = fig_height_per_row * len(criteria);
    colors = {"wins": "green", "ties": "orange", "losses": "red"};
    
    for (i, criterion) in enumerate(criteria) {
        criterion_data = df[df["criterion"] == criterion].sort_values("wins", ascending=False);
        for (j, outcome) in enumerate(["wins", "ties", "losses"]) {
            fig.add_trace(go.Bar(x=criterion_data["model"], y=criterion_data[outcome], text=criterion_data[outcome], textposition="auto", name=outcome.capitalize(), marker_color=colors[outcome], showlegend=(i == 0)), row=i + 1, col=1);
        }
    }
    fig.update_layout(barmode="stack", title="Model Performance by Criterion", height=total_fig_height);
    
    for (i, criterion) in enumerate(criteria) {
        fig.update_yaxes(title_text=criterion.capitalize(), row=i + 1, col=1, title_standoff=25);
    }
    st.plotly_chart(fig, use_container_width=True);
}

can generate_heatmaps(placeholder: str, model_performance: dict, preference_matrix: dict, all_models: list, criteria: list) {
    rows_list = [];
    
    for (model, crit_dict) in model_performance.items() {
        for (crit, win_tie_loss) in crit_dict.items() {
            rows_list.append({"model": model, "criterion": crit, "wins": win_tie_loss['wins'], "ties": win_tie_loss['ties'], "losses": win_tie_loss['losses']});
        }
    }
    df = pd.DataFrame(rows_list);
    global_max = df[["wins", "ties", "losses"]].max().max();
    global_min = df[["wins", "ties", "losses"]].min().max();
    subplot_titles = [];
    
    for crit in criteria {
        subplot_titles.append("Heatmap of Wins for " + crit);
        subplot_titles.append("Heatmap of Total Wins for " + crit);
    }
    fig = make_subplots(rows=len(criteria), cols=2, subplot_titles=subplot_titles, horizontal_spacing=0.15, specs=[[{}, {}]  for _ in range(len(criteria))]);
    global_individual_max = 0;
    
    for criterion in criteria {
        for model in all_models {
            max_wins = max(preference_matrix[criterion][model].values());
            global_individual_max = max(global_individual_max, max_wins);
        }
    }
    
    for (i, criterion) in enumerate(criteria) {
        can model_sorting_criteria(model: str) {
            total = sum(preference_matrix[criterion][model].values());
            return -total;
        }
        sorted_models = sorted(all_models, key=model_sorting_criteria);
        heatmap_data = np.zeros((len(sorted_models), len(sorted_models)), dtype=int);
        for (row, model1) in enumerate(sorted_models) {
            for (col, model2) in enumerate(sorted_models) {
                if (model1 != model2) {
                    heatmap_data[row, col] = preference_matrix[criterion][model1].get(model2, 0);
                }
            }
        }
        text = [[str(value)  for value in row]  for row in heatmap_data];
        fig.add_trace(go.Heatmap(z=np.flipud(heatmap_data), x=sorted_models, y=list(reversed(sorted_models)), colorscale="YlGnBu", zmin=0, zmax=global_individual_max, text=list(reversed(text)), texttemplate="%{text}", colorbar=dict(title="Individual Wins", len=0.7, y=(0.85 * (1 - (i / len(criteria)))), yanchor="bottom", x=1.1), showscale=(i == 0)), row=i + 1, col=1);
        total_wins_data = np.array([[wins]  for wins in heatmap_data.sum(axis=1)]);
        fig.add_trace(go.Heatmap(z=np.flipud(total_wins_data), x=["Total Wins"], y=list(reversed(sorted_models)), colorscale="BuPu", zmin=global_min, zmax=global_max, text=list(reversed(total_wins_data)), texttemplate="%{text}", colorbar=dict(title="Total Wins", len=0.7, y=(0.85 * (1 - (i / len(criteria)))), yanchor="bottom", x=1.2), showscale=(i == 0)), row=i + 1, col=2);
    }
    fig.update_layout(title_text="Model Performance by Criterion", height=350 * len(criteria), width=1500);
    if placeholder {
        with placeholder.container() {
            st.plotly_chart(fig, use_container_width=True);
        }
    } else {
        st.plotly_chart(fig, use_container_width=True);
    }
}
