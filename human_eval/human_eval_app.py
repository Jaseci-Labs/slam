import streamlit as st
import json
import os
import random
import time
import hashlib

# File paths
combinations_file = "data/all_task_completed/distributed_combinations_all_filtered.json"
unique_codes_file = "data/all_task_completed/unique_codes.json"
worker_count_file = "data/all_task_completed/worker_count.json"

st.set_page_config(layout="wide")
border_style = """
<style>
    .bordered-container {
        border: 2px solid #e1e4e8;
        border-radius: 5px;
        padding: 10px;
        margin: 10px 0;
    }
</style>
"""
st.markdown(border_style, unsafe_allow_html=True)


# Function to check if the worker has completed the task
def has_completed():
    try:
        with open(
            f"all_human_data_method_A_all/{st.session_state.worker_id}.json", "r"
        ) as file:
            all_selections = json.load(file)
        return True
    except (FileNotFoundError, json.JSONDecodeError):
        return False


# Function to retrieve a unique code for the user
def retrieve_unique_code():
    with open(unique_codes_file, "r") as file:
        unique_codes = json.load(file)
    if not unique_codes:
        raise Exception("No unique codes available.")
    user_code = unique_codes.pop(0)
    with open(unique_codes_file, "w") as file:
        json.dump(unique_codes, file)
    return user_code


# Function to mark task as completed
def mark_task_completed(worker_id, completion_code, worker_count):
    try:
        with open(
            f"all_human_data_method_A_all/{st.session_state.worker_id}.json", "r"
        ) as file:
            all_selections = json.load(file)
        all_selections.update(
            {
                "task_completed": True,
                "completion_code": completion_code,
                "worker_count": worker_count,
            }
        )
        with open(
            f"all_human_data_method_A_all/{st.session_state.worker_id}.json", "w"
        ) as file:
            json.dump(all_selections, file, indent=4)
    except (FileNotFoundError, json.JSONDecodeError):
        raise Exception(f"file nor found for worker_id {worker_id}")


# Function to update and get worker count
def update_and_get_worker_count():
    try:
        with open(worker_count_file, "r") as file:
            worker_count = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        worker_count = 0

    worker_count += 1
    with open(worker_count_file, "w") as file:
        json.dump(worker_count, file)

    return worker_count


def load_combinations():
    with open(combinations_file, "r") as file:
        return json.load(file)


def are_unique_codes_available():
    try:
        with open(unique_codes_file, "r") as file:
            unique_codes = json.load(file)
            return len(unique_codes) > 0
    except (FileNotFoundError, json.JSONDecodeError):
        return False


def main():
    # Initialization logic here...
    if "initialized" not in st.session_state:
        st.session_state.initialized = False
        st.session_state.current_index = 0
        st.session_state.start_time = time.time()
        st.session_state.evaluations = []
        st.session_state.worker_id = None
        st.session_state.worker_count = 0
        st.session_state.combinations = []
        st.session_state.pair_start_time = time.time()
        st.session_state.submitted = False

    # Prompt display logic here...
    prompt = 'Your task is to compare the output of two AI models on the set of criteria specified below. Please choose the model that you perceive to be better, or select "About the same" if there is no clear advantage one way or another. \n\n**The AI is called Myca and she is your personal assistant. You just completed all of your important tasks for today and she is giving you a compliment.**'
    st.markdown(
        f"<div class='bordered-container'><p><strong>Instructions</strong>:</p>{prompt}</div>",
        unsafe_allow_html=True,
    )
    # Worker ID input logic
    if not st.session_state.initialized:
        worker_id = st.text_input("Enter your worker ID", key="input_worker_id")
        if worker_id:
            st.session_state.worker_id = worker_id
            if has_completed():
                st.error("You have already completed this task. Thank you.")
            else:
                if are_unique_codes_available():
                    st.session_state.initialized = True
                    st.session_state.worker_count = update_and_get_worker_count()
                    st.session_state.combinations = load_combinations().get(
                        f"worker_{st.session_state.worker_count}", []
                    )
                else:
                    st.error(
                        "No unique codes are available at this time. Please try again later."
                    )
    if st.session_state.initialized and not st.session_state.submitted:
        if st.session_state.current_index < len(st.session_state.combinations):
            display_evaluation_interface()

    elif st.session_state.submitted:
        display_completion_message()


def display_evaluation_interface():
    if "show_warning" not in st.session_state:
        st.session_state.show_warning = False
    clarity_key = f"clarity_{st.session_state.current_index}"
    intelligence_key = f"intelligence_{st.session_state.current_index}"
    likability_key = f"likability_{st.session_state.current_index}"
    trustworthy_key = f"trustworthy_{st.session_state.current_index}"
    # Load the pair only if it hasn't been loaded before
    if f"pair_{st.session_state.current_index}" not in st.session_state:
        st.session_state[
            f"pair_{st.session_state.current_index}"
        ] = st.session_state.combinations[st.session_state.current_index]

    # Get the current pair from the session state
    pair = st.session_state[f"pair_{st.session_state.current_index}"]
    col1, col2, col3 = st.columns([5, 5, 5])
    # Calculate the current progress and total pairs
    total_pairs = len(st.session_state.combinations)
    current_pair_index = (
        st.session_state.current_index + 1
    )  # Adding 1 to start count from 1
    progress_fraction = current_pair_index / total_pairs

    # Display the progress bar and the count
    st.progress(progress_fraction)
    st.text(f"Pair {current_pair_index} of {total_pairs}")
    with col1:
        st.markdown(
            f"<div class='bordered-container'><p><strong>Model 1 Response:</strong></p>{pair['response1']}</div>",
            unsafe_allow_html=True,
        )
    with col3:
        st.markdown(
            f"<div class='bordered-container'><p><strong>Model 2 Response:</strong></p>{pair['response2']}</div>",
            unsafe_allow_html=True,
        )
    with col2:
        st.write(
            "<style>div.row-widget.stRadio > div{flex-direction:row;justify-content: center;} </style>",
            unsafe_allow_html=True,
        )
        st.markdown(
            """
                <style>
                div.row-widget.stRadio > div {
                    display: flex;
                    justify-content: center;
                }
                /* Center the label text of each radio button */
                div.row-widget.stRadio > label {
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                /* Optional: Adjust the padding and margin to reduce space */
                div.row-widget.stRadio {
                    margin-bottom: 0.25rem;
                    padding: 0.25rem;
                }
                </style>
                """,
            unsafe_allow_html=True,
        )
        options = ["Select an option", "1 is better", "About the same", "2 is better"]
        clarity = st.radio(
            "**Clarity/Conciseness**",
            options,
            key=clarity_key,
        )
        st.markdown(
            '<hr style="margin-top: 0.25rem; margin-bottom: 0.25rem;"/>',
            unsafe_allow_html=True,
        )
        intelligence = st.radio(
            "**Intelligence**",
            options,
            key=intelligence_key,
        )
        st.markdown(
            '<hr style="margin-top: 0.25rem; margin-bottom: 0.25rem;"/>',
            unsafe_allow_html=True,
        )
        likability = st.radio(
            "**Likability**",
            options,
            key=likability_key,
        )
        st.markdown(
            '<hr style="margin-top: 0.25rem; margin-bottom: 0.25rem;"/>',
            unsafe_allow_html=True,
        )
        trustworthy = st.radio(
            "**Trustworthy**",
            options,
            key=trustworthy_key,
        )
    preference_selected = (
        clarity != options[0]
        and likability != options[0]
        and intelligence != options[0]
        and trustworthy != options[0]
    )
    # Show warning if the user tries to proceed without making a selection
    if st.session_state.show_warning and not preference_selected:
        st.warning("Please select an option for all criteria before proceeding.")
    # 'Next Pair' button logic
    if st.session_state.current_index < len(st.session_state.combinations) - 1:
        if st.button("Next Pair") and preference_selected:
            save_current_evaluation(clarity, intelligence, likability, trustworthy)
            st.session_state.pair_start_time = time.time()
            st.session_state.current_index += 1
            st.session_state.show_warning = False
            st.experimental_rerun()
        else:
            st.session_state.show_warning = True
    # 'Submit Evaluations' button logic
    if st.session_state.current_index == len(st.session_state.combinations) - 1:
        if st.button("Submit Evaluations") and preference_selected:
            # Save the current evaluation
            save_current_evaluation(clarity, intelligence, likability, trustworthy)
            # Submit all evaluations
            st.session_state.submitted = True
            st.experimental_rerun()
        else:
            st.session_state.show_warning = True


def save_current_evaluation(clarity, intelligence, likability, trustworthy):
    pair = st.session_state[f"pair_{st.session_state.current_index}"]
    evaluations = {
        "response1": pair["response1"],
        "response2": pair["response2"],
        "clarity": clarity,
        "intelligence": intelligence,
        "likability": likability,
        "trustworthy": trustworthy,
        "time_spent": round(time.time() - st.session_state.pair_start_time, 2),
    }
    all_selections = {}
    try:
        with open(
            f"all_human_data_method_A_all/{st.session_state.worker_id}.json", "r"
        ) as file:
            all_selections = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        all_selections[str(st.session_state.worker_count)] = []
    all_selections["time_spent"] = round(time.time() - st.session_state.start_time, 2)
    all_selections[str(st.session_state.worker_count)].append(evaluations)

    with open(
        f"all_human_data_method_A_all/{st.session_state.worker_id}.json", "w"
    ) as file:
        json.dump(all_selections, file, indent=4)


def get_radio_index(choice):
    options = ["1 is better", "About the same", "2 is better"]
    return options.index(choice) if choice in options else 0


# Display completion message and code
def display_completion_message():
    completion_code = retrieve_unique_code()
    mark_task_completed(
        st.session_state.worker_id, completion_code, st.session_state.worker_count
    )
    st.success("Your evaluations have been submitted. Thank you!")
    st.write(f"Your completion code is: {completion_code}")


# Ensure the main function is called to run the app
if __name__ == "__main__":
    main()
