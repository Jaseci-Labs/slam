# Similarity Scorer Tutorial

## Introduction
Welcome to the Similarity Scorer tutorial for the SLAM Tool. This guide will walk you through the process of using the Similarity Scorer feature, that allows you to conduct detailed comparisons of language models based on their response similarity to a given anchor model's response. This tutorial will guide you through using the Similarity Scorer to evaluate and understand the nuances of different language models.

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