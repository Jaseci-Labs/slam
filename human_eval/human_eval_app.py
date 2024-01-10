import streamlit as st
import json
import random
from itertools import combinations
import hashlib
import time

# Initialize the session state variables
if "current_combination_index" not in st.session_state:
    st.session_state.current_combination_index = 0
    st.session_state.task_completed = False
    st.session_state.start_time = None
    st.session_state.models = []
    st.session_state.combinations = []
    st.session_state.worker_id = ""
    st.session_state.button_lock = False  # Initialize the button_lock here

# Load and parse the JSON data
with open("inputs.json", "r") as f:
    data = json.load(f)


# Function to check if the worker ID has already completed the task
def has_completed(worker_id, file_path="selections.json"):
    try:
        with open(file_path, "r") as file:
            all_selections = json.load(file)

        did_work = worker_id in all_selections and all_selections[worker_id][-1].get(
            "task_completed", False
        )
        print(f"Worker ID {worker_id} has completed the task: {did_work}")
        return did_work
    except (FileNotFoundError, json.JSONDecodeError):
        return False


# Function to generate a completion code
def generate_completion_code(worker_id):
    return hashlib.md5(worker_id.encode()).hexdigest()[:8]


# Function to mark the task as completed in the selections.json
def mark_task_completed(worker_id, file_path="selections.json"):
    try:
        with open(file_path, "r") as file:
            all_selections = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        all_selections = {}

    if worker_id in all_selections:
        all_selections[worker_id][-1]["task_completed"] = True
        with open(file_path, "w") as file:
            json.dump(all_selections, file, indent=4)


# Function to save the selection to a JSON file
def save_selection(worker_id, selection, start_time, file_path="selections.json"):
    try:
        with open(file_path, "r") as file:
            all_selections = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        all_selections = {}

    if worker_id not in all_selections:
        all_selections[worker_id] = []

    time_spent = round(time.time() - start_time, 2)
    selection["time_spent"] = time_spent
    all_selections[worker_id].append(selection)

    with open(file_path, "w") as file:
        json.dump(all_selections, file, indent=4)


# Function to get a random response from a model
def get_random_response(model_responses):
    return random.choice(model_responses)


# Function to move to the next pair of models
def next_pair():
    st.session_state.current_combination_index += 1
    if st.session_state.current_combination_index == len(st.session_state.combinations):
        st.session_state.task_completed = True


# Title and instructions
st.title("Human Evaluation of Responses")
evaluation_entry = data[0]
prompt = evaluation_entry["prompt"]

# Display the prompt
prompt_container = st.container()
prompt_container.text_area(
    "Prompt",
    value=prompt,
    height=150,
    max_chars=None,
    key=None,
    help=None,
    disabled=True,
)


def selection_made(selected_model):
    if st.session_state.button_lock:
        return

    st.session_state.button_lock = True  # Lock the buttons
    selection_info = {
        "model1": model1["model"],
        "model2": model2["model"],
        "selected": selected_model
        if selected_model == "tie"
        else selected_model["model"],
        "response1": response1,
        "response2": response2,
        "prompt": prompt,
        "time_spent": round(time.time() - st.session_state.start_time, 2),
        "task_completed": False,
    }
    save_selection(
        st.session_state.worker_id, selection_info, st.session_state.start_time
    )
    st.session_state.start_time = time.time()
    next_pair()
    st.session_state.button_lock = False  # Unlock the buttons


# MTurk Worker ID input
if not st.session_state.worker_id:
    worker_id = prompt_container.text_input(
        "Please enter your MTurk Worker ID to start the task.", key="input_worker_id"
    )
    if worker_id and has_completed(worker_id):
        st.error("This Worker ID has already completed the task.")
    elif worker_id:
        # Only proceed if the worker hasn't completed the task
        st.session_state.worker_id = worker_id
        st.session_state.start_time = time.time()
        st.session_state.models = evaluation_entry["responses"]
        st.session_state.combinations = list(
            combinations(range(len(st.session_state.models)), 2)
        )
        random.shuffle(st.session_state.combinations)  # Shuffle the combinations
        st.session_state.current_combination_index = 0
        st.session_state.task_completed = False


# Logic for model comparison and evaluation
if st.session_state.worker_id:
    if not st.session_state.task_completed:
        # Display progress bar and model responses only if task is not completed
        total_combinations = len(st.session_state.combinations)
        current_combination_index = st.session_state.current_combination_index
        progress_percentage = (current_combination_index + 1) / total_combinations
        st.progress(progress_percentage)

        idx1, idx2 = st.session_state.combinations[current_combination_index]
        model1 = st.session_state.models[idx1]
        model2 = st.session_state.models[idx2]

        response1 = get_random_response(model1["model_responses"])
        response2 = get_random_response(model2["model_responses"])

        col1, col2 = st.columns(2)

        with col1:
            st.subheader("Response 1")
            st.text_area(
                "First Model's Response", value=response1, height=150, disabled=True
            )
            if st.button("Response 1 is better", key="btn1"):
                selection_made(model1)

        with col2:
            st.subheader("Response 2")
            st.text_area(
                "Second Model's Response", value=response2, height=150, disabled=True
            )
            if st.button("Response 2 is better", key="btn2"):
                selection_made(model2)

        if st.button("Select this if there is a tie", key="tie"):
            selection_made("tie")
    else:
        # Task completed: display completion code
        completion_code = generate_completion_code(st.session_state.worker_id)
        mark_task_completed(st.session_state.worker_id)
        prompt_container.empty()
        st.success("The task has been completed.")
        st.write("Your completion code is:", completion_code)
