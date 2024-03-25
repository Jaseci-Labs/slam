import:py streamlit as st;

can about {
    github_mk = '''[![GitHub Repo stars](https://img.shields.io/github/stars/Jaseci-Labs/slam?style=social)](https://github.com/Jaseci-Labs/slam)''';
    citation = '''```Evgeny Pogrebnyak. (2021). Github data for static site generators (SSG) popularity (Version 0.1.2) [Data set]. Zenodo. http://doi.org/10.5281/zenodo.4429834```''';
    socials_mk = '''Please use GitHub [issues](https://github.com/Jaseci-Labs/slam/issues) for comments and suggestions or contact using links below. [![Twitter Follow](https://img.shields.io/twitter/follow/PogrebnyakE?label=Follow&style=social)](https://twitter.com/jasecilabs) [![Mail Badge](https://img.shields.io/badge/-e.pogrebnyak@gmail.com-c14438?style=flat-square&logo=Gmail&logoColor=white&link=mailto:chandra.irugalbandara@jaseci.org)](mailto:e.pogrebnyak@gmail.com)''';
    st.markdown(github_mk);
    st.header("Citation");
    st.markdown(citation);
    st.header("Contacts");
    st.markdown(socials_mk);
}
