import:py streamlit as st;

can about {
    github_mk = '''[![GitHub Repo stars](https://img.shields.io/github/stars/Jaseci-Labs/slam?style=social)](https://github.com/Jaseci-Labs/slam)''';
    citation = '''```Chandra Irugalbandara and Ashish Mahendra and Roland Daynauth and Tharuka Kasthuri Arachchige and Jayanaka Dantanarayana and Krisztian Flautner and Lingjia Tang and Yiping Kang and Jason Mars. (2024). Scaling Down to Scale Up: A Cost-Benefit Analysis of Replacing OpenAI's LLM with Open Source SLMs in Production. Arxiv. https://arxiv.org/abs/2312.14972```''';
    socials_mk = '''Please use GitHub [issues](https://github.com/Jaseci-Labs/slam/issues) for comments and suggestions or contact using links below. [![Twitter Follow](https://img.shields.io/twitter/follow/PogrebnyakE?label=Follow&style=social)](https://twitter.com/jasecilabs) [![Mail Badge](https://img.shields.io/badge/-chandra.irugalbandara@jaseci.org-c14438?style=flat-square&logo=Gmail&logoColor=white&link=mailto:chandra.irugalbandara@jaseci.org)](mailto:chandra.irugalbandara@jaseci.org)''';
    st.markdown(github_mk);
    st.header("Citation");
    st.markdown(citation);
    st.header("Contacts");
    st.markdown(socials_mk);
}