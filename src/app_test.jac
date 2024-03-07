import:py unittest;
import:py from streamlit.testing.v1, AppTest;

class TestSuite:unittest.TestCase: {
    can setUp {
        self.at = AppTest.from_file("app.py").run(timeout=20);
        assert not self.at.exception;
    }

    can test_login {
        admin_tab = self.at.get("tab")[1];
        assert admin_tab.label == "Admin Panel";

        admin_tab.text_input("username").input("admin");
        admin_tab.text_input("password").input("admin");
        admin_tab.get("button")[0].set_value(True).run();
        assert self.at.get("error")[1].value == "Invalid username or password";
        assert not self.at.session_state.admin_privileges;

        admin_tab.text_input("username").input("username");
        admin_tab.text_input("password").input("password");
        admin_tab.get("button")[0].set_value(True).run();
        assert self.at.session_state.admin_privileges;
    }

    can test_no_config {
        pass;
    }

    can test_setup {
        pass;
    }

    can test_human_eval {
        pass;
    }

    can test_dashboard {
        pass;
    }

    can test_generator {
        pass;
    }

    can auto_eval_llm_as_evaluator {
        pass;
    }

    can auto_eval_emb_sim_eval {
        pass;
    }
}

with entry {
    unittest.main();
}