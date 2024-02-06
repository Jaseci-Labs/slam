# LaME Tool : *La*nguage *M*odel *E*valuation Tool

LaME tool is a helper tool to evaluate the performance of LLMs for your personal usecases with the help of Human Evaluation and Automatic
 Evaluation through LLMs (Coming Soon). You can deploy the application on your local machine to first generate the necessary
responses for a given prompt with different LLMs (Propietary or OpenSource) and then evaluate the responses with the help of human evaluators.
 You can setup the human evaluation UI through the admin panel. Realtime Insights and Analytics are also provided to help
you understand the performance of the LLMs.

## Features

- **Admin Panel**: Setup the Human Evaluation UI and manage the human evaluators.
- **Realtime Insights and Analytics**: Get insights and analytics on the performance of the LLMs.
- **Human Evaluation**: Evaluate the responses of the LLMs with the help of human evaluators.
- **Automatic Evaluation**: Evaluate the responses of the LLMs with the help of LLMs (Coming Soon).
- **Multiple Model Support**: Generate responses for a given prompt with different LLMs (Propietary or OpenSource(Ollama)).

## Installation

### Prerequisites

- Python 3.6 or higher
- Docker (Optional)

### Docker Installation

Step 1: Pull the docker image from the docker hub

```bash
docker pull jaseci/slam-tool:latest
```

or

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
export SLAM_ADMIN_USERNAME=<user_name>
export SLAM_ADMIN_PASSWORD=<password>
```

Step 5: Run the application

```bash
streamlit run app.py
```

### Response Generation (Optional)

If you want to use the generate responses feature, you need to setup the LLMs.

Step 1: Setup the LLMs

If you are using OpenAI's GPT-4, you need to setup the API key.

```bash
export OPENAI_API_KEY=<api_key>
```

If you are using the Ollama's LLMs, You need to have the ollama installed and ollama server running.

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

## Walkthrough

TBA

## Contributing

We are open to contributions. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct,
and the process for submitting pull requests to us.
