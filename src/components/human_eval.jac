import:py streamlit as st;
import:py os;
import:py json;
import:py time;

can <>init;
can evaluation;
can captcha_gen;
can worker_id;

can human_eval {
    if "hv_config" not in st.session_state {<>init();}
    if st.session_state.get("hv_config", None) {
        if not st.session_state.worker_id or not st.session_state.is_human {
            (captcha_col, worker_id_col) = st.columns(2);
            with captcha_col {captcha_gen();}
            with worker_id_col {worker_id();}
        } else {
            if st.session_state.worker_count is None {
                if os.path.exists(os.path.join(".human_eval_config", "worker_count.txt")) {
                    with open(os.path.join(".human_eval_config", "worker_count.txt"), "r") as f {current_count = int(f.read());}
                } else {
                    with open(os.path.join(".human_eval_config", "worker_count.txt"), "w") as f {f.write("-1");}
                    current_count = -1;
                }
                if current_count >= st.session_state.hv_config["config"]["n_workers"] {
                    st.error("Something seems to be Wrong. Dev team is notified. Please Try Again Later. Thank You!");
                    return;
                }
                st.session_state.worker_count = current_count + 1;
                with open(os.path.join(".human_eval_config", "worker_count.txt"), "w") as f {f.write(str(st.session_state.worker_count));}
            }
            if not st.session_state.question_set_id {
                with open(os.path.join(".human_eval_config", "distribution.json"), "r") as f {all_questions = json.load(f);}
                st.session_state.question_set_id = list(all_questions.keys())[st.session_state.worker_count];
                st.session_state.question_set = all_questions[st.session_state.question_set_id];
                with open(os.path.join(".human_eval_config", "responses.json"), "r") as f {st.session_state.responses = json.load(f);}
                with open(os.path.join(".human_eval_config", "prompt_info.json"), "r") as f {st.session_state.prompt_info = json.load(f);}
            }
            
            if st.session_state.question_index < st.session_state.hv_config["config"]["n_questions_per_worker"] {
                evaluation();
            } else {
                st.markdown("Thank you for your participation!");
                st.markdown("You have completed all the questions.");
                st.markdown("Please copy the following code and paste it in the form to receive your payment.");
                st.markdown("```\n" + st.session_state.hv_config["config"]["completion_code"] + "\n```");
                if st.button("Do it again") {
                    with open(os.path.join(".human_eval_config", "worker_count.txt"), "r") as f {current_count = int(f.read());}
                    st.session_state.worker_count = current_count + 1;
                    with open(os.path.join(".human_eval_config", "worker_count.txt"), "w") as f {f.write(str(st.session_state.worker_count));}
                    st.session_state.question_set_id = None;
                    st.session_state.question_index = 0;
                    st.session_state.start_time = time.time();
                    st.session_state.evals = [];
                    st.rerun();
                }
            }
        }
    } else {
        st.error("No human eval config found.");
    }
}