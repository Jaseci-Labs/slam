import:py streamlit as st;
import:py os;
import:py from PIL, Image;

can local_css(file_name: str) -> None {
    with open(file_name, "r") as f {
        css = f.read();
        st.markdown(f"<style>{css}</style>", unsafe_allow_html=True);
    }
}

# can remote_css(url: str) -> None {
#     st.markdown(f"<link href='{url}' rel='stylesheet'>", unsafe_allow_html=True);
# }

can icon(icon_name: str) -> None {
    st.markdown(f"<i class='material-icons'>{icon_name}</i>", unsafe_allow_html=True);
}

can initPage(page_title: str) -> None {
    dir_root = os.path.dirname(os.path.abspath(__file__));
    favicon = Image.open(os.path.join(dir_root, "../assets/favicon.png"));
    st.set_page_config(page_title=page_title, page_icon=favicon);
    local_css(os.path.join(dir_root, "../assets/style.css"));

    # insert header brand with logo and link to website
    with open(os.path.join(dir_root, "../assets/theme.html")) as f {
        st.components.v1.html(f.read(), height=80);
    }
    st.header(page_title);
}

can footer {
    dir_root = os.path.dirname(os.path.abspath(__file__));
    local_css(os.path.join(dir_root, "../assets/footer.css"));
    footer= "<div class='footer'><p>Developed by <a href='https://www.jaseci.org/'' target='_blank'><img src='https://www.jaseci.org/wp-content/uploads/2022/02/jaseki-logo-inverted-rgb.svg' alt='Jaseci Logo' height='40'></a></p></div>";
    st.markdown(footer, unsafe_allow_html=True);
}