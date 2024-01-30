from jaclang import jac_import
import streamlit as st

st.set_page_config(page_title="SLaM Tool", page_icon=":robot_face:", layout="wide")
st_app = jac_import('src.app')
st_app.main()