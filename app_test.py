import unittest
import os
from streamlit.testing.v1 import AppTest


class TestSuite(unittest.TestCase):
    def setUp(self) -> None:
        self.at = AppTest.from_file("app.py").run(timeout=20)
        assert not self.at.exception

    def test_login(self) -> None:
        admin_tab = self.at.get("tab")[1]
        assert admin_tab.label == "Admin Panel"

        admin_tab.text_input("username").input("admin")
        admin_tab.text_input("password").input("admin")
        admin_tab.get("button")[0].set_value(True).run()
        assert self.at.get("error")[1].value == "Invalid username or password"
        assert not self.at.session_state.admin_privileges

        os.environ["SLAM_ADMIN_USERNAME"] = "username"
        os.environ["SLAM_ADMIN_PASSWORD"] = "password"

        admin_tab.text_input("username").input("username")
        admin_tab.text_input("password").input("password")
        admin_tab.get("button")[0].set_value(True).run()
        assert self.at.session_state.admin_privileges

    def test_no_config(self) -> None:
        pass

    def test_setup(self) -> None:
        pass

    def test_human_eval(self) -> None:
        pass

    def test_dashboard(self) -> None:
        pass

    def test_generator(self) -> None:
        pass

    def auto_eval_llm_as_evaluator(self) -> None:
        pass

    def auto_eval_emb_sim_eval(self) -> None:
        pass


unittest.main()
