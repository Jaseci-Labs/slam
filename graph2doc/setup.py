from setuptools import setup, find_packages

setup(
    name="graph2doc",
    version="0.1.0",
    description="A Python package for converting graphs to documents",
    author="Yiping Kang",
    author_email="yipingkang93@gmail.com",
    url="https://github.com/ypkang/rag-engine/graph2doc",
    packages=find_packages(),
    install_requires=[
        # Add any other dependencies here
    ],
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
    ],
)
