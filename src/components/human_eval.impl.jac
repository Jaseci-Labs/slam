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
        (col_a, col_result, col_b) = st.columns(3);
        with col_result {
            st.caption("Questions");
            with st.container(border=True) {
                overall = st.radio("Which one is better?", ["Response A", "Response B", "About the Same"], index=None,
                                    captions=["A is better", "B is better", "Both are equally good"], key=f"better_{question_index}");
            }
            feedback = st.text_area("Reasoning behind your choice", height=100, key=f"feedback_{question_index}");
            if overall and feedback {result = {"overall": overall, "feedback": feedback};}
            else {result = None;}
        }
    } else {
        st.markdown("You are given two responses below, evaluate them based on the criterias below.");
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

    if st.session_state.hv_config["hv_method"] == "A/B Testing with Criterions" {
        st.caption("Questions");
        (col_clarity, col_intelligence, col_likability, col_trustworthiness) = st.columns(4);
        with col_clarity {with st.container(border=True) {clarity = st.radio("Which has more clarity?", ["Response A", "Response B", "About the Same"], index=None,captions=["A is clearer", "B is clearer", "Both are equally clear"], key=f"clarity_{question_index}");}}
        with col_intelligence {with st.container(border=True) {intelligence = st.radio("Which is more intelligent?", ["Response A", "Response B", "About the Same"], index=None,captions=["A is more intelligent", "B is more intelligent", "Both are equally intelligent"], key=f"intelligence_{question_index}");}}
        with col_likability {with st.container(border=True) {likability = st.radio("Which is more likable?", ["Response A", "Response B", "About the Same"], index=None,captions=["A is more likable", "B is more likable", "Both are equally likable"], key=f"likability_{question_index}");}}
        with col_trustworthiness {with st.container(border=True) {trustworthiness = st.radio("Which is more trustworthy?", ["Response A", "Response B", "About the Same"], index=None,captions=["A is more trustworthy", "B is more trustworthy", "Both are equally trustworthy"], key=f"trustworthiness_{question_index}");}}
        (col_overall, col_feedback) = st.columns(2);
        with col_overall {with st.container(border=True) {overall = st.radio("Which is better overall?", ["Response A", "Response B", "About the Same"], index=None,captions=["A is better overall", "B is better overall", "Both are equally good overall"], key=f"overall_{question_index}");}}
        with col_feedback {with st.container(border=True) {feedback = st.text_area("Reasoning behind your choice", key=f"feedback_{question_index}");}}
        if clarity and intelligence and likability and trustworthiness and overall and feedback {
            result = {
                "clarity": clarity,
                "intelligence": intelligence,
                "likability": likability,
                "trustworthiness": trustworthiness,
                "overall": overall,
                "feedback": feedback
            };
        }
        else {result = None;}
    }
    
    if st.button("Next Question", <>type="primary", key=f"next_{question_index}") {
        if result {
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