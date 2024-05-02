# How to use SLaM for Automatic Evaluation

# LLM as an Evaluator

Other than using LLMs for generating responses, you can also use them as evaluators in the SLAM Tool. This guide will walk you through the process of using LLMs as evaluators in the SLAM Tool.

## Glossary
- **SLaM**: SLaM is a framework for human evaluation of language models for different tasks. It is designed to be flexible and easy to use, and it is built using [jaclang]().
- **Task**: The task is the specific problem that the language model is trying to solve. For example, the task could be to generate a summary of a given text, or to generate a response to a given prompt.
- **Language Model**: A language model is a model that is trained to generate text. It is trained on a large corpus of text and is used to generate text that is similar to the text in the training corpus.
- **Question**: One comparison between two outputs from different models. For example, the question could be "Which of the following outputs is more coherent?" and the two outputs could be "Output 1 from model 1" and "Output 2 from model 2".

## Prerequisites
Follow the steps given in the [README](../README.md) to install SLaM and its dependencies. Also make sure that a Human Evaluation is setupped in the SLAM Tool. Follow the [Human Evaluation](human_eval.md) tutorial to setup the Human Evaluation.

## Steps

### Check whetehr all the neccesary services are up and running
Makes sure the Query Engine is running. If not, run the following command to start the Query Engine.
```bash
uvicorn query_engine:serv_action --reload
```
If using Models from Ollama, make sure the Ollama server is running. If not, run the following command to start the Ollama server.
```bash
ollama serve
```

### Go to the Admin Panel >> Auto Evaluator >> LLM as an Evaluator
### Select the LLM to be used as an Evaluator
### Click `Run Auto Evaluation` to start the Auto Evaluation
### Have a cup of coffee and wait for the Auto Evaluation to complete
### Use the Dashboard to view the results

# Using Semantic Similarity to Evaluate Responses

This guide will walk you through the process of using the Similarity Scorer feature, that allows you to conduct detailed comparisons of language models based on their response similarity to a given anchor model's response. This tutorial will guide you through using the Similarity Scorer to evaluate and understand the nuances of different language models.

### Prerequisites

To make the most out of the Similarity Scorer in the SLAM Tool, it's important to be prepared. Here's what you'll need to get started:

1. **Access**: Make sure you can log into the SLAM Tool. You might need a username and password for this, so check that you have them handy.

2. **Data to Compare**: Gather the responses from the language models for the array of prompts you intend to compare.

## Step-by-Step Guide

### Step 1: Accessing the Similarity Scorer
Once you have logged into the SLAM Tool with your credentials, access the `Similarity Scorer` feature by going to the Admin Panel and selecting the `Auto Evaluator` option. Here you will find the `Similarity Scorer` tab.

### Step 2: Selecting Your Anchor Model
The anchor model is the reference point against which other models will be compared. Use the drop-down menu labeled `Select Anchor Model` to choose the desired anchor model. The default selection is typically GPT-4, a highly advanced language model.


### Step 3: Choosing the Embedder
The embedder is responsible for converting text responses into numerical vectors that can be compared. Select an embedding method that best suits your comparison needs from the `Select Type of Embedder` drop-down menu. The options include SBERT and other variants like USE and USE_QA.


### Step 4: Scoring Method
Decide on the metric for comparison by choosing a scorer. The "Select Scorer" drop-down menu lets you choose between cosine similarity (cos_sim) and semantic BLEU (sem_bleu). Cosine similarity measures the cosine of the angle between two vectors, while semantic BLEU evaluates the n-gram overlap adjusted by semantic embeddings.

### Step 5: Calculate Embedding Scores
After selecting your preferred anchor model, type of embedder, and scorer, you can begin the evaluation process by clicking the `Calculate Embedding Scores` button. This will prompt the tool to process the responses from the selected models, generate their embeddings, and calculate the similarity scores between them. Please be patient during this process; depending on the number of models and selections you have made, it may take a few minutes to several minutes to complete.

### Step 6: Reviewing Results

Following the completion of the calculation process, the results are displayed in various visual formats, including heatmaps and stacked bar plots, offering an intuitive representation of the models' performance in comparison to the anchor model.

- **Heatmap of Wins**: This heatmap displays the number of times a particular model's response was more similar to the anchor model's response compared to the other models. It allows for quick identification of which models align closely with the anchor model.

- **Heatmap of Total Wins**: This provides a cumulative view of the wins for each model across all comparisons, offering a measure of overall performance.

- **Stacked Bar Plots**: In addition to heatmaps, the results may also include stacked bar plots that delineate the wins, ties, and losses for each model. These plots provide a clear and detailed view of how often each model's responses were judged to be the best, tied with another model's, or not the closest to the anchor model's responses.

- **Further Analysis**
If you want to investigate a specific prompt's performance, select it from the `Select Prompt` drop-down menu. This will refresh the heatmaps to display data pertinent to that prompt only.


## Conclusion
The Similarity Scorer within the SLAM Tool is like a smart, detailed comparison shop for language models—it checks how similar the responses from different AI language models are to a chosen `anchor` model. Think of it like comparing different brands of smartphones to see which one is closest to the latest iPhone in terms of features.

When you use the Scorer, you're asking the tool to do a bunch of calculations to see which model's answers are most like the teacher's example. It uses some pretty clever math to figure this out, which can take a bit of time if you're comparing a lot of models at once.

The cool part comes when you get to see the results. They're shown in colorful heatmaps and bar charts that let you quickly see which model is the top of the class and which ones might need a bit more study. This isn't just useful for techies; it's also great for anyone interested in seeing how these AI brains stack up against each other.

In the end, the Similarity Scorer gives you a peek into how these AI language models think and talk, helping those who make them to tune them better and maybe even helping you pick your next AI chat buddy.