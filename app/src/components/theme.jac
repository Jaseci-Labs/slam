'''Theme Utils for Streamlit'''
import:py os;
import from PIL {Image}
import:py streamlit as st;

'''Load custom CSS for Streamlit app'''
can local_css(file_name: str) -> None {
    with open(file_name, "r") as f {
        css = f.read();
        st.markdown(f"<style>{css}</style>", unsafe_allow_html=True);
    }
}

'''Load custom JS for Streamlit app'''
can icon(icon_name: str) -> None {
    st.markdown(f"<i class='material-icons'>{icon_name}</i>", unsafe_allow_html=True);
}

'''Initialize a Streamlit page with custom title and favicon'''
can initPage(page_title: str) -> None {
    dir_root = os.path.dirname(os.path.abspath(__file__));
    favicon = Image.open(os.path.join(dir_root, "../assets/favicon.png"));
    st.set_page_config(page_title=page_title, page_icon=favicon);
    local_css(os.path.join(dir_root, "../assets/style.css"));
    
    with open(os.path.join(dir_root, "../assets/theme.html")) as f {
        st.html(f.read(), height=80);
    }
    st.header(page_title);
}

'''Add a footer to the Streamlit app'''
can footer {
    dir_root = os.path.dirname(os.path.abspath(__file__));
    local_css(os.path.join(dir_root, "../assets/footer.css"));
    footer = "<div class='footer' style='background-color: rgb(14, 17, 23);'><p style='color: white; margin: 5px;'>Developed by <a href='https://www.jaseci.org/'' target='_blank'><img src='https://www.jaseci.org/wp-content/uploads/2022/02/jaseki-logo-inverted-rgb.svg' alt='Jaseci Logo' height='40'></a></p></div>";
    st.markdown(footer, unsafe_allow_html=True);
}
