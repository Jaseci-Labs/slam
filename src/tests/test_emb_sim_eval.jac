import:py from streamlit.testing.v1, AppTest;
import:py os;
import:py json;
import:py shutil;
import:jac from utils, get_item_by_label;
import:py from pathlib, Path;

glob app = AppTest.from_file("app.py").run(timeout=20);


test app_running {
    :g: app;
    assert not app.exception;
    human_eval = Path(os.path.abspath(".human_eval_config"));
    if human_eval.exists(){shutil.rmtree(human_eval);}
}


test test_model_selection {
    shutil.unpack_archive(
        os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), "."
    );

    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();

    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    selectbox = get_item_by_label(app, "selectbox", "Select Anchor Model");
    
    selectbox.set_value(selectbox.options[0]).run();
    assert selectbox.value == "llama2:7b-chat";
    
    selectbox.set_value(selectbox.options[1]).run();
    assert selectbox.value == "mistral:7b-instruct";

    human_eval = Path(os.path.abspath(".human_eval_config"));
    if human_eval.exists(){shutil.rmtree(human_eval);}

}


test test_embedder_type_selection {
    shutil.unpack_archive(
        os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), "."
    );
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();
    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    selectbox = get_item_by_label(app, "selectbox", "Select Type of Embedder");
    selectbox.set_value(selectbox.options[0]).run();
    assert selectbox.value == "USE";
    selectbox.set_value(selectbox.options[1]).run();
    assert selectbox.value == "USE_QA";
    selectbox.set_value(selectbox.options[2]).run();
    assert selectbox.value == "SBERT";
    
    human_eval = Path(os.path.abspath(".human_eval_config"));
    if human_eval.exists(){shutil.rmtree(human_eval);}
}

test test_scorer_selection {
    shutil.unpack_archive(
        os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), "."
    );

    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();

    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    selectbox = get_item_by_label(app, "selectbox", "Select Scorer");
    
    selectbox.set_value(selectbox.options[0]).run();
    assert selectbox.value == "cos_sim";
    
    selectbox.set_value(selectbox.options[1]).run();
    assert selectbox.value == "sem_bleu";

    human_eval = Path(os.path.abspath(".human_eval_config"));
    if human_eval.exists(){shutil.rmtree(human_eval);}
}

test test_embedding_score_calculation {
    shutil.unpack_archive(
        os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), "."
    );
    app = AppTest.from_file("app.py").run(timeout=20);
    app.session_state.admin_privileges = True;
    app.run();

    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    calculate_embedding_score_button = get_item_by_label(app, "button", "Calculate Embedding Scores");
    calculate_embedding_score_button.set_value(True).run();
    spec = json.loads(app.get("plotly_chart")[0].proto.figure.spec);
    assert len(spec["data"]) > 0;

    human_eval = Path(os.path.abspath(".human_eval_config"));
    if human_eval.exists(){shutil.rmtree(human_eval);}
}