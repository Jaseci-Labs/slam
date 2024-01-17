import:py streamlit as st;
import:py json;
import:py random;
import:py from itertools, combinations;
import:py hashlib;
import:py time;
import:py os;

can has_completed(worker_id: str, file_path: str) -> bool {
    try {
        with open(file_path, "r") as file {
            all_selections = json.load(file);
        }

        did_work = worker_id in all_selections and all_selections.get("task_completed", False);
        print(f"Worker ID {worker_id} has completed the task: {did_work}");
        return did_work;
    } except (FileNotFoundError, json.JSONDecodeError) {
        return False;
    }
}

# # Function to read responses and generate combinations
# can read_responses_and_generate_combinations(directory: str) -> list {
#     responses = {};
#     for filename in os.listdir(directory) {
#         if filename.endswith('.json') {
#             with open(os.path.join(directory, filename), 'r') as file {
#                 data = json.load(file);
#                 model_name = filename.replace('.json', '');
#                 responses[model_name] = [resp["response"] for resp in data['outputs'][:5]];
#             }
#         }
#     }
#     all_combinations = [];
#     model_names = list(responses.keys());
#     for i in range(len(model_names)){
#         for j in range(i + 1, len(model_names)){
#             for response1 in responses[model_names[i]]{
#                 for response2 in responses[model_names[j]]{
#                     all_combinations.append({"model1": model_names[i], "response1": response1, "model2": model_names[j], "response2": response2});
#                 }
#             }
#         }
#     }
#     random.shuffle(all_combinations);
#     return all_combinations;
# }


# can read_responses_distribute_among_workers(directory: str, num_workers: int) -> None {
#     responses = {};
#     for filename in os.listdir(directory) {
#         if filename.endswith('.json') {
#             with open(os.path.join(directory, filename), 'r') as file {
#                 data = json.load(file);
#                 model_name = filename.replace('.json', '');
#                 responses[model_name] = [resp["response"] for resp in data['outputs'][:5]];
#             }
#         }
#     }

#     all_combinations = [];
#     model_names = list(responses.keys());
#     for i in range(len(model_names)) {
#         for j in range(i + 1, len(model_names)) {
#             for response1 in responses[model_names[i]] {
#                 for response2 in responses[model_names[j]] {
#                     all_combinations.append({"model1": model_names[i], "response1": response1, "model2": model_names[j], "response2": response2});
#                 }
#             }
#         }
#     }
#     random.shuffle(all_combinations);

#     distributed_combinations = {};
#     num_combinations_per_worker = len(all_combinations) // num_workers;
#     remaining_combinations = len(all_combinations) % num_workers;

#     for i in range(num_workers) {
#         worker_id = f"worker_{i+1}";
#         start_index = i * num_combinations_per_worker;
#         end_index = start_index + num_combinations_per_worker;
#         worker_combinations = all_combinations[start_index:end_index];

#         # Distribute remaining combinations among first few workers
#         if i < remaining_combinations {
#             worker_combinations.append(all_combinations[len(all_combinations) - remaining_combinations + i]);
#         }

#         distributed_combinations[worker_id] = worker_combinations;
#     }

#     # Save the distributed combinations to a file
#     with open("distributed_combinations.json", "w") as file {
#         json.dump(distributed_combinations, file);
#     }
# }


# can assign_worker_combinations(worker_id: str, all_combinations: list, num_workers: int) -> list {
#     worker_index = get_worker_index(worker_id, num_workers);
#     num_combinations_per_worker = int(len(all_combinations) / num_workers);
#     start_index = worker_index * num_combinations_per_worker;
#     worker_combinations = all_combinations[start_index:start_index + num_combinations_per_worker];

#     remaining_combinations = len(all_combinations) % num_workers;
#     if remaining_combinations > 0 {
#         index_of_remaining = num_workers * num_combinations_per_worker + worker_index;
#         if index_of_remaining < len(all_combinations) {
#             worker_combinations.append(all_combinations[index_of_remaining]);
#         }
#     }
#     return worker_combinations;
# }



# can get_worker_index(worker_id: str, num_workers: int) -> int {
#     worker_hash = int(hashlib.md5(worker_id.encode()).hexdigest(), 16);
#     worker_index = worker_hash % num_workers;
#     return worker_index;
# }

# can assign_pairs_to_worker(worker_index: int, all_pairs: list, num_pairs_per_worker: int) -> list {
#     start_index = worker_index * num_pairs_per_worker;
#     worker_pairs = all_pairs[start_index:start_index + num_pairs_per_worker];
#     return worker_pairs;
# }
can update_and_get_worker_count(file_path: str = "worker_count.json") -> int {
    worker_count = 0;
    try {
        with open(file_path, "r") as file {
            worker_count = json.load(file);
        }
        worker_count += 1;
        with open(file_path, "w") as file {
            json.dump(worker_count, file);
        }
    } except Exception as e {
        # If file does not exist, initialize it
        with open(file_path, "w") as file {
            json.dump(1, file);
        }
        worker_count = 1;
    }
    return worker_count;
}
# Retrieve a unique code for the user
can retrieve_unique_code(file_path: str = "unique_codes.json") -> str {
    with open(file_path, "r") as file {
        unique_codes = json.load(file);
    }
    if not unique_codes{
        raise Exception("No unique codes available.");
    }
    # Pop the first code from the list to ensure uniqueness
    user_code = unique_codes.pop(0);

    # Store the updated list back to the file
    with open(file_path, "w") as file{
        json.dump(unique_codes, file);
    }
    return user_code;
}

can mark_task_completed(worker_id: str, completion_code:str, file_path: str ) -> None {
    try {
        with open(file_path, "r") as file {
            all_selections = json.load(file);
        }
    } except (FileNotFoundError, json.JSONDecodeError) {
        all_selections = {};
    }

    if worker_id in all_selections {
        all_selections["task_completed"] = True;
        all_selections["completion_code"] = completion_code;
        with open(f"human_response_output_all/{worker_id}.json", "w") as file {
            json.dump(all_selections, file, indent=4);
        }
    }
}

can save_selection(worker_id: str, selection: dict, start_time: float, file_path: str ) -> None {
    try {
        with open(file_path, "r") as file {
            all_selections = json.load(file);
        }
    } except (FileNotFoundError, json.JSONDecodeError) {
        all_selections = {};
    }

    if worker_id not in all_selections {
        all_selections[worker_id] = [];
    }

    time_spent = round(time.time() - start_time, 2);
    selection["time_spent"] = time_spent;
    all_selections[worker_id].append(selection);

    with open(file_path, "w") as file {
        json.dump(all_selections, file, indent=4);
    }
}

can get_random_response(model_responses: list) -> str {
    return random.choice(model_responses);
}

can next_pair(evaluation_mode: str) -> None {
    st.session_state.current_combination_index += 1;
    
    if evaluation_mode == "GPT_4_vs_Others" {
        if st.session_state.current_combination_index == len(st.session_state.current_model_responses) {
            st.session_state.task_completed = True;
        }
    } elif evaluation_mode == "All_vs_All" {
        if st.session_state.current_combination_index == len(st.session_state.combinations) {
            st.session_state.task_completed = True;
        }
    }
}

can selection_made(selected_model: str, model1: str, model2: str, response1: str, response2: str, prompt: str, evaluation_mode: str="GPT_4_vs_Others") -> None {
    if st.session_state.button_lock {
        return;
    }

    st.session_state.button_lock = True;  # Lock the buttons
    selection_info = {
        "model1": model1["name"],
        "model2": model2["name"],
        "selected": selected_model if selected_model == "tie" else selected_model["name"],
        "response1": response1,
        "response2": response2,
        "prompt": prompt,
        "time_spent": round(time.time() - st.session_state.start_time, 2)
    };
    save_selection(st.session_state.worker_id, selection_info, st.session_state.start_time,f"human_response_output_all/{st.session_state.worker_id}.json");
    st.session_state.start_time = time.time();
    next_pair(evaluation_mode);
    st.session_state.button_lock = False;  # Unlock the buttons
}

can read_responses(directory: str) -> dict {
    responses = [];
    prompt = "";
    gpt4_response = None;  # Variable to store GPT-4's response

    for filename in os.listdir(directory) {
        if filename.endswith('.json') {
            with open(os.path.join(directory, filename), 'r') as file {
                data = json.load(file);
                model_responses=[];
                model_name = filename.replace('.json', '');
                for response in data['outputs'] {
                    model_responses.append(response["response"]);
                }
                if model_name == "gpt-4" {
                    prompt = data['full_prompt'];  # Assuming this is where the prompt is stored
                    gpt4_response = {"model_responses":model_responses};
                } else {
                    responses.append({"model":model_name,"model_responses":model_responses});
                }
            }
        }
    }

    if gpt4_response is None {
        raise ValueError("GPT-4 responses not found in the given directory");
    }

    return {"prompt": prompt, "gpt4": gpt4_response, "other_models": responses};
}

can evaluate_gpt4_vs_others(evaluation_data: dict, prompt: str) -> None {
    if not st.session_state.current_model_responses {
        st.session_state.current_model_responses = evaluation_data["other_models"];
    }

    # Display progress bar and model responses
    total_models = len(st.session_state.current_model_responses);
    current_index = st.session_state.current_combination_index;
    progress_percentage = (current_index + 1) / total_models;
    st.progress(progress_percentage);

    # Get the current non-GPT-4 model to compare
    current_model = st.session_state.current_model_responses[current_index];
    gpt4_response = random.choice(st.session_state.gpt4_responses);  # Random GPT-4 response
    current_model_response = random.choice(current_model["model_responses"]);  # Random current model response

    # Randomly determine the order of models for display
    models = [
        {"name": "GPT-4", "response": gpt4_response},
        {"name": current_model["model"], "response": current_model_response}
    ];
    random.shuffle(models);  # Shuffle the models to randomize the order

    display_model_responses(models, prompt);
}


can evaluate_all_vs_all(evaluation_data: dict, prompt: str) -> None {
    # Display progress bar and model responses
    total_combinations = len(st.session_state.combinations);
    current_combination_index = st.session_state.current_combination_index;
    progress_percentage = (current_combination_index + 1) / total_combinations;
    st.progress(progress_percentage);

    # Get the current combination assigned to the worker
    current_combination = st.session_state.combinations[current_combination_index];
    model1_name = current_combination["model1"];
    model2_name = current_combination["model2"];
    response1 = current_combination["response1"];
    response2 = current_combination["response2"];

    models = [
        {"name": model1_name, "response": response1},
        {"name": model2_name, "response": response2}
    ];

    display_model_responses(models, prompt,evaluation_mode="All_vs_All");
}


can display_model_responses(models: list, prompt: str, evaluation_mode: str="GPT_4_vs_Others") -> None {
    (col1, col2) = st.columns(2);

    with col1 {
        st.subheader("Response 1");
        st.text_area("First Model's Response", value=models[0]["response"], height=200, disabled=True);
        if st.button("Response 1 is better", key="btn1") {
            selection_made(models[0], models[0], models[1], models[0]["response"], models[1]["response"], prompt, evaluation_mode);
        }
    }

    with col2 {
        st.subheader("Response 2");
        st.text_area("Second Model's Response", value=models[1]["response"], height=200, disabled=True);
        if st.button("Response 2 is better", key="btn2") {
            selection_made(models[1], models[0], models[1], models[0]["response"], models[1]["response"], prompt, evaluation_mode);
        }
    }

    if st.button("Select this if there is a tie", key="tie") {
        selection_made("tie", models[0], models[1], models[0]["response"], models[1]["response"], prompt, evaluation_mode);
    }
}


can main(evaluation_mode: str="All_vs_All") {
    # Initialize the session state variables
    st.set_page_config(layout="wide");
    if "current_combination_index" not in st.session_state {
        st.session_state.current_combination_index = 0;
        st.session_state.task_completed = False;
        st.session_state.start_time = None;
        st.session_state.current_model_responses = [];  # Store the current non-GPT-4 model responses
        st.session_state.gpt4_responses = [];  # Store GPT-4 responses
        st.session_state.worker_id = "";
        st.session_state.button_lock = False;  # Initialize the button_lock here
    }


    file_directory = 'first_run';
    evaluation_data = read_responses(file_directory);
    prompt = evaluation_data["prompt"];
    # Set up the session state for models and combinations based on the mode    
    if "setup_done" not in st.session_state or not st.session_state.setup_done {
        if evaluation_mode == "GPT_4_vs_Others" {
            st.session_state.current_model_responses = evaluation_data["other_models"];
        } elif evaluation_mode == "All_vs_All" {
            with open("distributed_combinations.json", "r") as file {
                st.session_state.distributed_combinations = json.load(file);
            }
        }
        st.session_state.setup_done = True;
    }

    # Store GPT-4 responses in session state
    if not st.session_state.gpt4_responses {
        st.session_state.gpt4_responses = evaluation_data["gpt4"]["model_responses"];
    }
    # Title and instructions
    st.title("Human Evaluation of LLM Responses");

    # Display the prompt
    prompt_container = st.container();
    prompt_container.text_area("Prompt", value=prompt, height=220, max_chars=None, key=None, help=None, disabled=True);



    # MTurk Worker ID input
    if "worker_id" not in st.session_state or not st.session_state.worker_id {
        worker_id = prompt_container.text_input("Please enter your Worker ID to start the task.", key="input_worker_id");
        if worker_id and has_completed(worker_id,f"human_response_output_all/{worker_id}.json") {
            st.error("This Worker ID has already completed the task.");
            st.session_state.worker_id = None; 
        } elif worker_id and  "worker_count" not in st.session_state {
            # Only proceed if the worker hasn't completed the task
            st.session_state.worker_id = worker_id;
            st.session_state.start_time = time.time();
            st.session_state.current_combination_index = 0;
            st.session_state.task_completed = False;
            st.session_state.worker_count = update_and_get_worker_count();
            st.session_state.combinations = st.session_state.distributed_combinations[f"worker_{st.session_state.worker_count}"];
            
        }
    } 
    if combinations in st.session_state {
        print(st.session_state.combinations);
    }
    # Logic for model comparison and evaluation 
    if st.session_state.worker_id {
        if not st.session_state.task_completed {
            if evaluation_mode == "GPT_4_vs_Others"{
                evaluate_gpt4_vs_others(evaluation_data, prompt);
            }
            elif evaluation_mode == "All_vs_All"{
                evaluate_all_vs_all(evaluation_data, prompt);
            }
        }
        else {
            completion_code = retrieve_unique_code();
            mark_task_completed(st.session_state.worker_id, completion_code,f"human_response_output_all/{st.session_state.worker_id}.json");
            prompt_container.empty();
            st.success("The task has been completed.");
            st.write("Your completion code is:", completion_code);
        }
    }
}