import:py streamlit as st;
import:py os;
import:py json;
import:py time;
import:py re;
import:jac from utils, llms, check_engine_status, load_engine, run_inference;

:can:llm_as_evaluator {
    st.title("LLM as an Evaluator");
    st.caption("LLM as an Evaluator simulates an human evaluator");
    if "llm_as_eval_config" not in st.session_state {
        <>init();
    }
    if st.session_state.get("llm_as_eval_config", None) {
        engine_status = check_engine_status();
        eval_model = st.selectbox("Select the Model which will Act as an Evaluator", llms);
        with open(os.path.join(".human_eval_config", "distribution.json"), "r") as f {
            all_questions = json.load(f);
        }
        if eval_model and engine_status {
            if st.button("Run Auto Evaluation") {
                run_llm_as_evaluator(eval_model, all_questions);
            }
        } else {
            st.error("Please Select a Model and Start the Engine First");
        }
    } else {
        st.error("No human eval config found. Please Initialize a Human Evaluation First.");
    }
}

:can:<>init {
    if os.path.exists(os.path.join(".human_eval_config", "config.json")) {
        st.session_state.llm_as_eval_config = json.load(open(os.path.join(".human_eval_config", "config.json")));
        with open(os.path.join(".human_eval_config", "prompt_info.json"), "r") as f {
            st.session_state.prompt_info = json.load(f);
        }
        with open(os.path.join(".human_eval_config", "responses.json"), "r") as f {
            st.session_state.responses = json.load(f);
        }
        os.makedirs("results", exist_ok=True);
    }
}

:can:run_llm_as_evaluator
(eval_model: str, all_questions: dict) {
    with st.spinner(f"Running LLM as Evaluator with {eval_model}... Please Wait") {
        (provider_name, model_name) = eval_model.split('/');
        engine_loaded = False;
        prompt_template_file = "prefer.prt" if st.session_state.llm_as_eval_config["hv_method"] == "A/B Testing" else "criteria.prt";
        with open(os.path.join("src", "assets", "promp_templates", prompt_template_file), "r") as f {
            prompt_template = f.read();
        }
        with st.spinner(f"Loading model {model_name}...") {
            engine_loaded = load_engine(provider_name, model_name, 0.0, prompt_template);
        }
        if engine_loaded {
            for (question_set_id, question_set) in all_questions.items() {
                evals = [];
                for question in question_set {
                    prompt_id = question[0];
                    prompt_disc = [x["prompt_simple_disc"]  for x in st.session_state.prompt_info if x["prompt_id"] == prompt_id][0];
                    (model_a, model_a_respones_id) = list(question[1].items())[0];
                    (model_b, model_b_respones_id) = list(question[1].items())[1];
                    model_a_respones = st.session_state.responses[model_a_respones_id];
                    model_b_respones = st.session_state.responses[model_b_respones_id];
                    arguments = {"usecase":prompt_disc, "response_a":model_a_respones, "response_b":model_b_respones };
                    try  {
                        inference_result = run_inference(model_name, 1, arguments);
                        question_result = process_inference_result(inference_result['outputs'][0]['response']);
                        evals.append({"result":question_result, "time":time.time(), "question":question, "inference_result":inference_result });
                    } except Exception as e  {
                        evals.append({"result":str(e), "time":time.time(), "question":question });
                    }
                }
                with open(os.path.join("results", f"llm_as_evaluator_{question_set_id}.json"), "w") as f {
                    json.dump({"worker_id":"llm_as_evaluator", "question_set_id":question_set_id, "evals":evals, "start_time":time.time(), "end_time":time.time() }, f, indent=2);
                }
            }
        } else {
            st.error(f"Failed to load model {model_name}");
        }
    }
    st.success(f"Evaluation completed successfully!");
}

:can:process_inference_result
(inference_result: dict) -> dict {
    try  {
        answers = eval(re.search(r"\[Output\](.*)", inference_result, re.DOTALL).group(1).strip());
        answers["feedback"] = re.search(r"\[Reasoning\](.*)\[Output\]", inference_result, re.DOTALL).group(1).strip();
    } except Exception as e  {
        answers = {"error":str(e) };
    }
    return answers;
}
