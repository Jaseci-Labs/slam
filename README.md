# SLaM Tool : *S*mall *La*nguage *M*odel Evaluation Tool

SLaM tool is a helper tool to evaluate the performance of LLMs for your personal use cases with the help of Human Evaluation and Automatic
 Evaluation through LLMs (Coming Soon). You can deploy the application on your local machine to first generate the necessary
responses for a given prompt with different LLMs (Proprietary or OpenSource) and then evaluate the responses with the help of human evaluators.
 You can set up the human evaluation UI through the admin panel. Realtime Insights and Analytics are also provided to help
you understand the performance of the LLMs.

## Features

- **Admin Panel**: Set up the Human Evaluation UI and manage the human evaluators.
- **Realtime Insights and Analytics**: Get insights and analytics on the performance of the LLMs.
- **Human Evaluation**: Evaluate the responses of the LLMs with the help of human evaluators.
- **Automatic Evaluation**: Evaluate the responses of the LLMs with the help of LLMs (Coming Soon).
- **Multiple Model Support**: Generate responses for a given prompt with different LLMs (Proprietary or OpenSource(Ollama)).

## Installation

### Prerequisites

- Python 3.12 or higher
- Docker (Optional)

### Docker Installation

Step 1: Pull the docker image from the docker hub

```bash
docker build -t jaseci/slam-tool:latest .
```

Step 2: add the following environment variables to the container to setup the admin panel

```bash
docker run -p 8501:8501 -e SLAM_ADMIN_USERNAME=<user_name> -e SLAM_ADMIN_PASSWORD=<password> jaseci/slam-tool:latest
```

Step 3: Open the browser and go to the following link

```bash
http://localhost:8501
```

### Local Installation

Step 1: Clone the repository

```bash
git clone https://github.com/Jaseci-Labs/slam.git && cd slam
```

Step 2: Create a virtual environment (Optional)

```bash
conda create -n slam-tool python=3.11 -y
conda activate slam-tool
```

Step 3: Install the requirements

```bash
pip install -r requirements.txt
```

Step 4: Setup the environment variables

```bash
export SLAM_ADMIN_USERNAME=<username>
export SLAM_ADMIN_PASSWORD=<password>
```

Step 5: Run the application

```bash
streamlit run app.py
```

### Response Generation (Optional)

If you want to use the generate responses feature, you need to set up the LLMs.

Step 1: Setup the LLMs

If you are using OpenAI's GPT-4, you need to set up the API key.

```bash
export OPENAI_API_KEY=<api_key>
```

If you are using Ollama's LLMs, You need to have the Ollama installed and Ollama server running.

```bash
curl https://ollama.ai/install.sh | sh
ollama serve
```

Step 2: Run the Query Engine

```bash
uvicorn query_engine:serv_action --reload
```

Step 3: Environment Variables (Optional)

```bash
export ACTION_SERVER_URL=http://localhost:8000/
export OLLAMA_SERVER_URL=http://localhost:11434/
```

## Tutorials

- [How to use SLaM for Human Evaluation](docs/tutorials/human_eval.md)
- [How to Generate Responses using SLaM](docs/tutorials/response_generator.md)
- [How to use SLaM for Automatic Evaluation](docs/tutorials/automatic_eval.md)
    - [LLM as an Evaluator](docs/tutorials/automatic_eval.md#llm-as-an-evaluator)
    - [Using Semantic Similarity to Evaluate Responses](docs/tutorials/automatic_eval.md#using-semantic-similarity-to-evaluate-responses)
- [How to Get Realtime Insights and Analytics from your Evaluations](docs/tutorials/insights_analytics.md)

## Tips and Tricks

### Continuos Backup of Results

if you want to have a continuous backup of the results to a Google Drive folder. You can do the following.

Step 1: Set the Google Drive folder id as an environment variable
```bash
export GDRIVE_FOLDER_ID=<folder_id>
```

Step 2: Initiate a CRON Job to run the `scripts/backup.jac` every 5 minutes. Make sure to have an oauth file (`setting.yaml` and `credentials.json`) in the folder you initiate the cron job.
```bash
# activate the virtual environment where jaclang is installed
*/5 * * * * jac run scripts/backup.jac
```

Follow the [PyDrive OAuth](https://pythonhosted.org/PyDrive/oauth.html) to set up the oauth files.

### Loading BackUps

Step 1: Open the App and Login with the admin credentials
Step 2: Go to the Dashboard page and Drag and Drop your Zip file
Step 3: Click Upload and Unzip
Step 4: Click Refresh to see the Diagrams and Visualizations

## Contributing

We are open to contributions. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct,
and the process for submitting pull requests to us.
