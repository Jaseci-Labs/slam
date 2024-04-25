# How to use SLaM for Human Evaluation

This tutorial will guide you through the process of using SLaM for human evaluation for your specific use case.

<!-- TODO: Add the Video -->

## Glossary
- **SLaM**: SLaM is a framework for human evaluation of language models for different tasks. It is designed to be flexible and easy to use, and it is built using [jaclang]().
- **Human Evaluation**: Human evaluation is the process of evaluating the performance of a language model by asking humans which is the best out of a given set of outputs (the identity of the model is hidden from the human evaluators). This is done to understand how well the model is performing and to compare different models for a given task.
- **Task**: The task is the specific problem that the language model is trying to solve. For example, the task could be to generate a summary of a given text, or to generate a response to a given prompt.
- **Language Model**: A language model is a model that is trained to generate text. It is trained on a large corpus of text and is used to generate text that is similar to the text in the training corpus.
- **Question**: One comparison between two outputs from different models. For example, the question could be "Which of the following outputs is more coherent?" and the two outputs could be "Output 1 from model 1" and "Output 2 from model 2".

## Prerequisites
Follow the steps given in the [README](../README.md) to install SLaM and its dependencies.

## Steps
### Prepare the data
The first step is to prepare the data for human evaluation. This involves collecting the outputs of the language model for a given task or multiple tasks. You can do this through the [Response Generator](response_generator.md) feature of SLaM. Follow the instructions in the [Response Generator](response_generator.md) tutorial to generate the responses for your specific task. or you can create your own responses and store them in a file according to the following JSON format. You will need multiple files for each task you want to evaluate.

```json
{
    "prompt": "The prompt for the task (Optional)",
    "prompt_disc": "In Markdown format. This will be visible to the human evaluators",
    "outputs": {
        "model_1": [
            "Output 1 from model 1",
            "Output 2 from model 1",
            "Output 3 from model 1",
            "..."
        ],
        "model_2": [
            "Output 1 from model 2",
            "Output 2 from model 2",
            "Output 3 from model 2",
            "..."
        ]
    }
}
```
> **NOTICE:** Make sure to generate enough samples for each model to be evaluated. It is recommended to have at least 10 samples for each model.

### Deciding on the Human Evaluation Settings
The next step is to decide on the settings for the human evaluation. This includes deciding on the number of human evaluators, the number of questions to be evaluated by each evaluator, and the evaluation methodology to be used etc.

Usually in an experiment like this, we normally perform a internal evaluation before going for crowd-sourcing. This is to ensure that the evaluation is consistent and the evaluators are able to understand the task and the evaluation process and also maybe to get the baseline experiment results. Though the internal evaluation is not mandatory, it is recommended to perform it before going for crowd-sourcing.

The Setting for the both internal and crowd-sourcing evaluation is similar. The only difference is the number of evaluators. For internal evaluation, you can use 3-5 evaluators and for crowd-sourcing, you can use any number of evaluators based on your budget.

When you running the internal evaluation, Make sure to set true to `evenly distributed`. This will make sure the questions are distributed evenly among the evaluators such that each evaluator gets the same number of questions from each task.

- **Number of Workers**: The number of human evaluators that will be used for the human evaluation.
- **Number of Questions per Worker**: The number of questions that each human evaluator will be asked to evaluate.
- **Evenly Distributed**: If set to `true`, the questions will be distributed evenly among the evaluators such that each evaluator gets the same number of questions from each task.
- **Show Captcha**: If set to `true`, the human evaluators will be asked to solve a captcha before they can start the evaluation. This is to prevent bots from participating in the evaluation.
- **Data Source**: The data source for the human evaluation. Set of files in the format mentioned in the previous step. Each file should represent a task.

### Setting Up the Human Evaluation
Once you have prepared the data and decided on the settings, you can set up the human evaluation using the `Setup` Tab in the Admin Panel.

Select the relevant tasks, settings that is decided on [Step 2]() and the data that is prepared on [Step 1]() and click on `Save`. This will create all the necessary files and folders for the human evaluation.

### Conducting the Human Evaluation
Once the human evaluation is set up, you can start conducting the human evaluation. You can do this by sharing the link to the human evaluation with the human evaluators. You can use the follwing HTML code to embed the human evaluation in a platform of your choice.

```html
<div class="col-xs-12 col-md-6 col-md-offset-3">
<table class="table table-condensed table-bordered">
	<tbody>
		<tr>
			<td><strong>Task link:</strong></td>
			<td><a class="btn btn-primary" href="<link_to_slam>" target="_blank">Open Task</a></td>
		</tr>
	</tbody>
</table>
</div>
```
> **Notice:** If you are running the SLaM on a Virtual Machine, make sure to use a tool like tmux or screen to keep the server running even after you close the terminal.

## Next Steps
- [Realtime Metrics](dashboard.md): Learn how to monitor the human evaluation in real-time.
- [Setting Up Automatic Backups](backup.md): Learn how to set up automatic backups for the human evaluation data.
- [Using Auto Evaluatior](auto_evaluator.md): Learn how to use the Auto Evaluator to get the evaluation results.