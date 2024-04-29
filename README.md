# SLaM Tool : *S*mall *La*nguage *M*odel Evaluation Tool

[![Query Engine Tests](https://github.com/Jaseci-Labs/slam/actions/workflows/query_engine_test.yml/badge.svg)](https://github.com/Jaseci-Labs/slam/actions/workflows/query_engine_test.yml)
[![SLaM App Tests](https://github.com/Jaseci-Labs/slam/actions/workflows/app_test.yml/badge.svg)](https://github.com/Jaseci-Labs/slam/actions/workflows/app_test.yml)

SLaM Tool is a helper tool to evaluate the performance of Large Language Models (LLMs) for your personal use cases with the help of Human Evaluation and Automatic Evaluation. You can deploy the application on your local machine or use Docker to generate responses for a given prompt with different LLMs (Proprietary or OpenSource), and then evaluate the responses with the help of human evaluators or automated methods.

## Features

- **Admin Panel**: Set up the Human Evaluation UI and manage the human evaluators.
- **Realtime Insights and Analytics**: Get insights and analytics on the performance of the LLMs.
- **Human Evaluation**: Evaluate the responses of the LLMs with the help of human evaluators.
- **Automatic Evaluation**: Evaluate the responses of the LLMs with the help of LLMs and using embedding similarity.
- **Multiple Model Support**: Generate responses for a given prompt with different LLMs (Proprietary or OpenSource(Ollama)).

## Installation

First Clone the Repository:

```bash
git clone https://github.com/Jaseci-Labs/slam.git && cd slam
``` 

### Prerequisites

- Python 3.12 or higher
- Docker (Optional)

### Only the Human Evaluation Tool

#### Using Docker

1. Build the Docker Image:
   ```bash
   cd app
   docker build -t slam/slam-app:latest .
   ```

2. Run the container with environment variables:
   ```bash
   docker run -p 8501:8501 -e SLAM_ADMIN_USERNAME=<user_name> -e SLAM_ADMIN_PASSWORD=<password> slam/slam-app:latest
   ```

3. Open your browser and go to `http://localhost:8501`

#### Using Local Installation

1. Create a virtual environment (optional):
   ```bash
   cd app
   conda create -n slam-app python=3.12 -y
   conda activate slam-app
   ```

2. Install the requirements:
   ```bash
   pip install -r requirements.txt
   ```

3. Set environment variables:
   ```bash
   export SLAM_ADMIN_USERNAME=<username>
   export SLAM_ADMIN_PASSWORD=<password>
   ```

4. Run the application:
   ```bash
   streamlit run app.py
   ```

5. Open your browser and go to `http://localhost:8501`


### With the Query Engine and Ollama
Notice: Make Sure you are running in an environment with GPU

#### Using Docker Compose (Recommended)

1. Build the Docker Images:
   ```bash
   docker compose up -d --build
   ```

2. Open your browser and go to `http://localhost:8501`

#### Using Local Installation

Follow the Steps above to install the app and then follow the steps below to install the Query Engine and Ollama.

### For Response Generation & Automatic Evaluation (Optional)

For a streamlined experience, SLAM offers the option to leverage LLMs and SLMs for response generation and automated evaluation.

Open a new terminal window and navigate to the root directory of the SLAM repository.

1. Create a seperate virtual environment (Recommended):

   ```bash
   cd engine
   conda create -n slam-engine python=3.12 -y
   conda activate slam-engine
   ```

2. Install the dependencies:

   ```bash
   pip install -r engine/requirements.txt
   ```

3. Run the Query Engine:

   ```bash
   jac run src/query_engine.jac
   ```

4. Run the Ollama Server:

   ```bash
   curl https://ollama.ai/install.sh | sh
   ollama serve
   ```

5. If you plan to use OpenAI's GPT-4, set the API key:

   ```bash
   export OPENAI_API_KEY=<your_api_key>
   ```
   if you have a remote ollama server, set the server url:
   ```bash
   export OLLAMA_SERVER_URL=http://<remote_server_ip>:11434/
   ```

## Tutorials

- [How to Generate Responses using SLaM](docs/tutorials/response_generator.md)
- [How to use SLaM for Human Evaluation](docs/tutorials/human_eval.md)
- [How to use SLaM for Automatic Evaluation](docs/tutorials/automatic_eval.md)
    - [LLM as an Evaluator](docs/tutorials/automatic_eval.md#llm-as-an-evaluator)
    - [Using Semantic Similarity to Evaluate Responses](docs/tutorials/automatic_eval.md#using-semantic-similarity-to-evaluate-responses)
- [How to Get Realtime Insights and Analytics from your Evaluations](docs/tutorials/insights_analytics.md)

## Tips and Tricks

### Continuous Backup of Results

SLAM offers a convenient option to maintain a continuous backup of your results to a Google Drive folder, ensuring your data is securely stored and easily accessible.

1. **Set the Google Drive Folder ID**

   First, set the Google Drive folder ID as an environment variable:

   ```bash
   export GDRIVE_FOLDER_ID=<your_folder_id>
   ```

2. **Initiate a CRON Job**

   Next, initiate a CRON job to run the `scripts/backup.jac` script every 5 minutes. Ensure that you have an OAuth file (`settings.yaml` and `credentials.json`) in the folder from which you initiate the CRON job.

   ```bash
   # Activate the virtual environment where JacLang is installed
   */5 * * * * jac run scripts/backup.jac
   ```

Follow the [PyDrive OAuth](https://pythonhosted.org/PyDrive/oauth.html) instructions to set up the OAuth files.

### Loading Backups

To load your backups, follow these simple steps:

1. **Open the App and Log In**
   - Launch the SLAM application and log in with your admin credentials.

2. **Navigate to the Dashboard**
   - Once logged in, navigate to the Dashboard page.

3. **Upload and Unzip**
   - Drag and drop your ZIP file onto the designated area.
   - Click the "Upload and Unzip" button.

4. **Refresh and View**
   - After the upload process is complete, click the "Refresh" button to see the updated diagrams and visualizations.


## FAQ

1. When Trying to run `ollama serve` I get an error `Error: listen tcp :11434: bind: address already in use`
   - This error occurs when the port 11434 is already in use. To resolve this issue, you can either kill the process running on the port using `sudo systemctl stop ollama` and then run `ollama serve` again.

2. When trying to run the Query Engine, I get an error `Error: No module named 'jac'`
   - This error occurs when the `jaclang` package is not installed. To resolve this issue, first makesure you are in the `slam-engine` environment and and retry installing the requirements using `pip install -r engine/requirements.txt`.

3. If you have any other questions, please feel free to reach out to us through the [Issues](https://github.com/Jaseci-Labs/slam/issues) section.



## Contributing

We welcome contributions to enhance SLAM's capabilities. Please review the [CONTRIBUTING.md](CONTRIBUTING.md) file for our code of conduct and the process for submitting pull requests. We appreciate your interest in contributing to SLAM and look forward to your valuable contributions.
