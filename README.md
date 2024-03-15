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

### Prerequisites

- Python 3.12 or higher
- Docker (Optional)

### Docker Installation

1. Build the Docker Image:
   ```bash
   docker build -t jaseci/slam-tool:latest .
   ```

2. Run the container with environment variables:
   ```bash
   docker run -p 8501:8501 -e SLAM_ADMIN_USERNAME=<user_name> -e SLAM_ADMIN_PASSWORD=<password> jaseci/slam-tool:latest
   ```

3. Open your browser and go to `http://localhost:8501`

### Local Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Jaseci-Labs/slam.git && cd slam
   ```

2. Create a virtual environment (optional):
   ```bash
   conda create -n slam-tool python=3.12 -y
   conda activate slam-tool
   ```

3. Install the requirements:
   ```bash
   pip install -r requirements.txt
   ```

4. Set environment variables:
   ```bash
   export SLAM_ADMIN_USERNAME=<username>
   export SLAM_ADMIN_PASSWORD=<password>
   ```

5. Run the application:
   ```bash
   streamlit run app.py
   ```

### For Response Generation & Automatic Evaluation (Optional)

For a streamlined experience, SLAM offers the option to leverage LLMs and SLMs for response generation and automated evaluation.

1. **Configure Language Models**

   If you prefer utilizing OpenAI's GPT-4, you'll need to set up an API key:
   
   ```bash
   export OPENAI_API_KEY=<your_api_key>
   ```

   Alternatively, if you choose to employ Ollama's cutting-edge language models, ensure that you have Ollama installed and the server running:
   
   ```bash
   curl https://ollama.ai/install.sh | sh
   ollama serve
   ```

2. **Installing Dependencies & Launch the Query Engine**

    Query Engine Requires more complex dependancies than the normal app. (Use of Sepeate Python Environment is Recommended)
    
    ```bash
    pip install -r requirements.dev.txt
    ```

    Once the language models are configured, initiate the Query Engine:
    
    ```bash
    jac run src/query_engine.jac
    ```

3. **Optional Environment Variables**

    For added flexibility, you can set the following environment variables:
    
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

## Contributing

We welcome contributions to enhance SLAM's capabilities. Please review the [CONTRIBUTING.md](CONTRIBUTING.md) file for our code of conduct and the process for submitting pull requests.

To run the test suite, execute the following command:

```bash
sh scripts/run_tests.sh
```

We appreciate your interest in contributing to SLAM and look forward to your valuable contributions.
