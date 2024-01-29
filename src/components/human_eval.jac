import:py streamlit as st;
import:py os;
import:py json;
import:py time;
import:py from captcha.image, ImageCaptcha;
import:py random;
import:py string;

can init;
can evaluation;
can captcha;
can worker_id;

can human_eval {
    if "config" not in st.session_state {init();}
    if st.session_state.config and st.session_state.worker_count {
        if not st.session_state.question_set_id {
            with open(os.path.join(".human_eval_config", "distribution.json"), "r") as f {all_questions = json.load(f);}
            st.session_state.question_set_id = list(all_questions.keys())[st.session_state.worker_count];
            st.session_state.question_set = all_questions[st.session_state.question_set_id];
            with open(os.path.join(".human_eval_config", "responses.json"), "r") as f {st.session_state.responses = json.load(f);}
            with open(os.path.join(".human_eval_config", "prompt_info.json"), "r") as f {st.session_state.prompt_info = json.load(f);}
        }

        if not st.session_state.worker_id or not st.session_state.is_human {
            (captcha_col, worker_id_col) = st.columns(2);
            with captcha_col {captcha();}
            with worker_id_col {worker_id();}
        }else {
            if st.session_state.question_index < st.session_state.config["config"]["n_questions_per_worker"] {
                evaluation();
            } else {
                st.markdown("Thank you for your participation!");
                st.markdown("You have completed all the questions.");
                st.markdown("Please copy the following code and paste it in the form to receive your payment.");
                st.markdown("```\n" + st.session_state.question_set_id + "\n```");
            }
        }
    } else {
        st.error("No human eval config found.");
    }
}

:can:evaluation {
    st.progress(st.session_state.question_index / st.session_state.config["config"]["n_questions_per_worker"],
    "Question " + str(st.session_state.question_index + 1) + " / " + str(st.session_state.config["config"]["n_questions_per_worker"]));

    question = st.session_state.question_set[st.session_state.question_index];
    model_a = question[0][0];
    model_b = question[0][1];
    model_a_respones = st.session_state.responses[question[1][0]];
    model_b_respones = st.session_state.responses[question[1][1]];

    with st.expander("Instructions", expanded=True) {
        st.markdown(st.session_state.prompt_info["prompt_disc"]);
    }

    if st.session_state.config["hv_method"] == "A/B Testing" {
        (col_a, col_result, col_b) = st.columns(3);
        with col_result {
            st.caption("Questions");
            with st.container(border=True) {
                result = st.radio("Which one is better?", ["Response A", "Response B", "Both"], index=None,
                                    captions=["A is better", "B is better", "Both are equally good"]);
            }
        }
    } else {
        (col_a, col_b) = st.columns(2);
    }
    
    with col_a {
        st.caption("Response A");
        with st.container(border=True) {
            st.markdown(model_a_respones);
        }
    }
    with col_b {
        st.caption("Response B");
        with st.container(border=True) {
            st.markdown(model_b_respones);
        }
    }

    if st.session_state.config["hv_method"] == "A/B Testing with Criterions" {
        st.caption("Questions");
        (col_clarity, col_intelligence, col_likability, col_trustworthiness) = st.columns(4);
        with col_clarity {with st.container(border=True) {clarity = st.radio("Which has more clarity?", ["Response A", "Response B", "Both"], index=None,captions=["A is clearer", "B is clearer", "Both are equally clear"]);}}
        with col_intelligence {with st.container(border=True) {intelligence = st.radio("Which is more intelligent?", ["Response A", "Response B", "Both"], index=None,captions=["A is more intelligent", "B is more intelligent", "Both are equally intelligent"]);}}
        with col_likability {with st.container(border=True) {likability = st.radio("Which is more likable?", ["Response A", "Response B", "Both"], index=None,captions=["A is more likable", "B is more likable", "Both are equally likable"]);}}
        with col_trustworthiness {with st.container(border=True) {trustworthiness = st.radio("Which is more trustworthy?", ["Response A", "Response B", "Both"], index=None,captions=["A is more trustworthy", "B is more trustworthy", "Both are equally trustworthy"]);}}
        if clarity and intelligence and likability and trustworthiness {result = (clarity, intelligence, likability, trustworthiness);}
        else {result = None;}
    }
    
    if st.button("Next Question") {
        if result {
            st.session_state.evals.append({"result": result, "time": time.time()});
            st.session_state.question_index += 1;
            with open(f"{st.session_state.worker_id}_{st.session_state.question_set_id}.json", "w") as f {json.dump(st.session_state.evals, f, indent=2);}
            st.rerun();
        } else {
            st.error("Please provide answers to all questions.");
        }
    }
}

:can:captcha {
    with st.container(border=True) {
        if not st.session_state.is_human {
            st.session_state.captcha = ''.join(random.choices(string.ascii_uppercase + string.digits, k=5)) if not st.session_state.captcha else st.session_state.captcha;
            captcha_img = ImageCaptcha().generate(st.session_state.captcha);
            st.image(captcha_img, caption="Please enter the captcha above to prove that you are a human.");
            captcha_input = st.text_input("Captcha");
            if captcha_input {
                if captcha_input.upper() == st.session_state.captcha.upper() {
                    st.session_state.is_human = True;
                    st.rerun();
                } else {
                    st.error("Captcha is incorrect. Please try again.");
                    if st.button("Refresh Captcha") {
                        st.session_state.captcha = ''.join(random.choices(string.ascii_uppercase + string.digits, k=5));
                        st.rerun();
                    }
                }
            }
        } else {
            st.info("You have passed the captcha test. Please enter your worker ID to start the survey.");
        }
    }
}

:can:worker_id {
    with st.container(border=True) {
        st.session_state.worker_id = st.text_input("Worker ID");
        if st.session_state.worker_id {st.rerun();}
        st.caption("Please enter your worker ID to start the survey. Make sure to use the correct worker ID, otherwise you will not be paid.");
    }
}

:can:init {
    if os.path.exists(".human_eval_config") and os.path.exists(os.path.join(".human_eval_config", "config.json")) {
        if "config" not in st.session_state {
            st.session_state.config = None;
            st.session_state.worker_count = None;
            st.session_state.question_index = 0;
            st.session_state.start_time = time.time();
            st.session_state.evals = [];
            st.session_state.worker_id = None;
            st.session_state.captcha = None;
            st.session_state.is_human = False;
            st.session_state.question_set_id = None;
            st.session_state.question_set = None;
            st.session_state.responses = None;
            st.session_state.prompt_info = None;
        }
        os.makedirs("results", exist_ok=True);
        human_eval_config = json.load(open(os.path.join(".human_eval_config", "config.json"), "r"));
        if os.path.exists(os.path.join(".human_eval_config", "worker_count.txt")) {
            with open(os.path.join(".human_eval_config", "worker_count.txt"), "r") as f {current_count = int(f.read());}
            with open(os.path.join(".human_eval_config", "worker_count.txt"), "w") as f {f.write(str(current_count + 1));}
        } else {
            with open(os.path.join(".human_eval_config", "worker_count.txt"), "w") as f {f.write("-1");}
        }
        st.session_state.config = human_eval_config;
        st.session_state.worker_count = current_count + 1;
    }
}

