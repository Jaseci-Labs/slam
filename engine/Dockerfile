FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

HEALTHCHECK CMD curl --fail http://localhost:8000

ENTRYPOINT ["jac", "run", "src/query_engine.jac"]