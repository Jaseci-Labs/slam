import:py json;
import:py os;
import:py from pathlib, Path;
import:py shutil;
import:py from streamlit.testing.v1, AppTest;

import:jac from helpers, get_item_by_label;


test app_running   {
    :g: app ;
    app = AppTest.from_file("app.py").run(timeout=20);
    assert not app.exception;
}

test test_model_selection   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "data.zip"), ".");
    app.session_state.admin_privileges = True;
    app.run();
    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    anchor_selector = get_item_by_label(sim_scorer_tab, "selectbox", "Select Anchor Model");
    embedder_selector = get_item_by_label(sim_scorer_tab, "selectbox", "Select Type of Embedder");
    scorer_selector = get_item_by_label(sim_scorer_tab, "selectbox", "Select Scorer");
    assert anchor_selector.options == ['llama2:7b-chat', 'mistral:7b-instruct'];
    assert embedder_selector.options == ['USE', 'USE_QA', 'SBERT'];
    assert scorer_selector.options == ['cos_sim', 'sem_bleu'];
}

test test_embedding_score_calculation   {
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "config.zip"), ".");
    shutil.unpack_archive(os.path.join(os.path.dirname(__file__), "fixtures", "data.zip"), ".");
    app.session_state.admin_privileges = True;
    app.run();
    sim_scorer_tab = get_item_by_label(app, "tab", "Similarity Scorer");
    get_item_by_label(sim_scorer_tab, "button", "Calculate Embedding Scores").set_value(True).run(timeout=200);
    assert len(os.listdir(os.path.join("results", "llama2:7b-chat_SBERT_cos_sim"))) > 0;
    shutil.rmtree("results");
    shutil.rmtree(".human_eval_config");
    shutil.rmtree("data");
}
