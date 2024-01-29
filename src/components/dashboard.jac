import:py streamlit as st;
import:py os;

can init {
    if os.path.exists("results") and len(os.listdir("results")) > 0 {
        results = os.listdir("results");
    } else {
        st.error("Results were not found. Initialize a Human Evaluation first or wait until the results are ready.");
    }
}

can dashboard {
    st.title("Dashboard");
}