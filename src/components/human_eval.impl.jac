import:py os;
import:py json;
import:py time;
import:py streamlit as st;
import:py from captcha.image, ImageCaptcha;
import:py random;
import:py string;

:can:<>init {
    if os.path.exists(os.path.join(".human_eval_config", "config.json")) {
        if "hv_config" not in st.session_state {
            st.session_state.hv_config = None;
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
        if not human_eval_config["config"]["show_captcha"] {st.session_state.is_human = True;}
        st.session_state.hv_config = human_eval_config;
    }
}

:can:worker_id {
    with st.container(border=True) {
        st.session_state.worker_id = st.text_input("Worker ID");
        if st.session_state.worker_id {st.rerun();}
        st.caption("Please enter your worker ID to start the survey. Make sure to use the correct worker ID, otherwise you will not be paid.");
    }
}

:can:captcha_gen {
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

:can:evaluation {
    st.progress(st.session_state.question_index / st.session_state.hv_config["config"]["n_questions_per_worker"],
    "Question " + str(st.session_state.question_index + 1) + " / " + str(st.session_state.hv_config["config"]["n_questions_per_worker"]));

    question_index = st.session_state.question_index;
    question = st.session_state.question_set[question_index];
    prompt_id = question[0];
    prompt_disc = [x["prompt_disc"] for x in st.session_state.prompt_info if x["prompt_id"] == prompt_id][0];
    (model_a, model_a_respones_id) = list(question[1].items())[0];
    (model_b, model_b_respones_id) = list(question[1].items())[1];
    model_a_respones = st.session_state.responses[model_a_respones_id];
    model_b_respones = st.session_state.responses[model_b_respones_id];

    with st.expander("Instructions", expanded=True) {
        st.markdown(prompt_disc, unsafe_allow_html=True);
    }

    if st.session_state.hv_config["hv_method"] == "A/B Testing" {
        st.markdown("You are given two responses below, Select which one you prefer.");
        result = {"overall": None, "feedback": None};
        (col_a, col_result, col_b) = st.columns(3);
        with col_result {
            st.caption("Questions");
            with st.container(border=True) {
                result["overall"] = st.radio("Which one is better?", ["Response A", "Response B", "About the Same"], index=None,
                                    captions=["A is better", "B is better", "Both are equally good"], key=f"better_{question_index}");
            }
            result["feedback"] = st.text_area("Reasoning behind your choice", height=100, key=f"feedback_{question_index}");
        }
    } else {
        st.markdown("You are given two responses below, evaluate them based on the criterias below.");
        (col_a, col_b) = st.columns(2);
    }
    

    if st.session_state.hv_config["hv_method"] == "A/B Testing with Criterions" {
        st.caption("Questions");
        result = {x["Criteria"]: None for x in st.session_state.hv_config["criterias"]};
        result["feedback"] = None;
        n_criterias = len(st.session_state.hv_config["criterias"]);
        for i in range(int(n_criterias/4) + 1) {
            cols = st.columns(4);
            for j in range(4) {
                if i*4+j >= n_criterias {break;}
                with cols[j] {
                    with st.container(border=True) {
                        criteria = st.session_state.hv_config["criterias"][i*4+j];
                        result[criteria["Criteria"]] = st.radio(criteria["Description"], ["Response A", "Response B", "About the Same"], index=None,
                                                               key=f"{criteria['Criteria']}_{question_index}");
                    }
                }
            }
        }
        result["feedback"] = st.text_area("Reasoning behind your choice", height=100, key=f"feedback_{question_index}");
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
    
    if st.button("Next Question", <>type="primary", key=f"next_{question_index}") {
        if all(result.values()) {
            st.session_state.evals.append({"result": result, "time": time.time(), "question": question});
            st.session_state.question_index += 1;
            with open(os.path.join("results", f"{st.session_state.worker_id}_{st.session_state.question_set_id}.json"), "w") as f {
                json.dump({
                    "worker_id": st.session_state.worker_id,
                    "question_set_id": st.session_state.question_set_id,
                    "evals": st.session_state.evals,
                    "start_time": st.session_state.start_time,
                    "end_time": time.time(),
                    "question_index": st.session_state.question_index
                }, f, indent=2);
            }
            st.components.v1.html("<script>window.parent.document.querySelector('section.main').scrollTo(-1, -1);</script>", height=0);
            time.sleep(0.5);
            st.rerun();
        } else {
            st.error("Please provide answers to all questions.");
        }
    }
}