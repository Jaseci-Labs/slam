import:py json;
import:py os;
import:py from datetime, datetime;

can generate_performance_data(
    formatted_output:dict, 
    all_models:list, 
    prompt_id:str, 
    criteria:list) {
    if (not criteria) {
        criteria = [
            "overall",
            "clarity",
            "intelligence",
            "likability",
            "trustworthiness"
        ];
    }

    model_performance = {
        model: {
            criterion: {"wins": 0, "ties": 0, "losses": 0} for criterion in criteria
        } for model in all_models
    };
    preference_matrix = {
        criterion: {
            model: {
                other_model: 0 for other_model in all_models if other_model != model
            } for model in all_models
        } for criterion in criteria
    };
    for outputs in formatted_output {
        if (prompt_id == "all_combined" or outputs["prompt_id"] == prompt_id) {
            for response in outputs["responses"] {
                model1 = response["model_a"];
                model2 = response["model_b"];
                for crit in criteria {
                    result = response.get(crit);
                    if (result == "Response A") {
                        model_performance[model1][crit]["wins"] += 1;
                        model_performance[model2][crit]["losses"] += 1;
                        preference_matrix[crit][model1][model2] += 1;
                    } elif (result == "Response B") {
                        model_performance[model1][crit]["losses"] += 1;
                        model_performance[model2][crit]["wins"] += 1;
                        preference_matrix[crit][model2][model1] += 1;
                    } else {  # Ties
                        model_performance[model1][crit]["ties"] += 1;
                        model_performance[model2][crit]["ties"] += 1;
                    }
                }
            }
        }
    }

    return (model_performance, preference_matrix, criteria);
}

can format_responses_by_prompt(workers_data_dir:str, distribution_file:str, response_file:str) {
    out_dataset = {};

    with open(distribution_file, "r") as file {
        distribution = json.load(file);
    }
    with open(response_file, "r") as file {
        all_responses = json.load(file);
    }
    for filename in os.listdir(workers_data_dir) {
        file_path = os.path.join(workers_data_dir, filename);
        if (os.path.isfile(file_path)) {
            try {
                with open(file_path, "r") as file {
                    worker_data = json.load(file);
                }
            } except Exception as e {
                print(f"Error reading {file_path}: {e}");
                continue;
            }
            if ("question_index" in worker_data and worker_data["question_index"] == 10) {
                curr_distribution_set = distribution.get(worker_data["question_set_id"], None);
                if (curr_distribution_set != None) {
                    for (i, curr_worker_data) in enumerate(worker_data["evals"]) {
                        curr_worker_data = worker_data["evals"][i];
                        curr_set = curr_worker_data.get("question");
                        prompt_id = curr_set[0];
                        model_names = list(curr_set[1].keys());
                        (model_a, response_a_id) = (
                            model_names[0],
                            curr_set[1][model_names[0]]
                        );
                        (model_b, response_b_id) = (
                            model_names[1],
                            curr_set[1][model_names[1]]
                        );
                        response_a = all_responses.get(response_a_id, None);
                        response_b = all_responses.get(response_b_id, None);

                        curr_resp_contruct = {
                            "model_a": model_a,
                            "response_a": response_a,
                            "model_b": model_b,
                            "response_b": response_b,
                            "worker_id": worker_data["worker_id"]
                        };
                        curr_resp_contruct.update(curr_worker_data["result"]);
                        if (i == 0) {
                            start_time = datetime.fromtimestamp(worker_data["start_time"]);
                        }
                        end_time = datetime.fromtimestamp(curr_worker_data["time"]);
                        curr_resp_contruct.update({
                            "time_taken": (end_time - start_time).total_seconds()
                        });
                        start_time = end_time;
                        if (prompt_id not in out_dataset) {
                            out_dataset[prompt_id] = [];
                        }
                        out_dataset[prompt_id].append(curr_resp_contruct);
                    }
                }
            }
        }
    }

    formatted_output = [
        {"prompt_id": prompt_id, "responses": responses} for (prompt_id, responses) in out_dataset.items()
    ];
    return formatted_output;
}

