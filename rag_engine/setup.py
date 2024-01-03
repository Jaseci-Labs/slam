from setuptools import setup, find_packages

setup(
    name="rag_engine",
    version="0.1",
    packages=find_packages(),
    install_requires=["openai", "langchain", "llama_index"],
    author="Jaseci Labs",
)
