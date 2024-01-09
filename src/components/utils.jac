import:py requests;
import:py json;
import:py os;
import:py shutil;
import:py time;
import:py from yaspin, yaspin;

glob ACTION_SERVER_URL = "http://localhost:8000/";

can call_action(action:str, **kwargs: dict) -> dict {
    url = f"{ACTION_SERVER_URL}{action}";
    response = requests.post(url, json=kwargs);
    return response.json();
}

can wrap_text(text:str, max_length:int = 80) -> str {
    can wrap_line(line:str) {
        while len(line) > max_length {
            break_index = line.rfind(" ", 0, max_length);
            if break_index == -1 {
                break_index = max_length;
            }
            yield line[:break_index];
            line = line[break_index:].lstrip();
        }
        yield line;
    }
    lines = text.split("\n");
    wrapped_lines = [wrapped_line for line in lines for wrapped_line in wrap_line(line)];
    return "\n".join(wrapped_lines);
}

can load_context(context_path:str) -> dict {
    with open(os.path.join(os.path.dirname(__file__), "context_input", context_path), "r") as f {
        context = json.load(f);
    }
    if isinstance(context, dict) and "report" in context {
        context = context["report"][0];
    }
    return context;
}

can save_conv(feature_name:str, feature_config:dict, conv:dict, new_config:bool) {
    feature_dir = os.path.join(os.path.dirname(__file__), "features", feature_name, "latest");
    if new_config {
        ts = conv["timestamp"];
        dest_dir = os.path.join(os.path.dirname(__file__), "features", feature_name, ts);

        shutil.move(feature_dir, dest_dir);
        os.makedirs(feature_dir, exist_ok=True);

        with open(os.path.join(feature_dir, "config.json"), "w") as f {
            json.dump(feature_config, f, indent=2);
        }
    }

    with open(os.path.join(feature_dir, f"conv_{conv['timestamp']}"), 'w') as f {
        json.dump(conv, f, indent=2);
    }
}

can run_experiment(query:str, feature_name:str, model_name:str, query_context:dict, num_samples:int = 1) -> dict {
    outputs = [];
    for i in range(num_samples) {
        with yaspin(text=f"Running experiment for {model_name} ({i+1}/{num_samples})...", color="yellow") {
            try {
                start_time = time.time();
                ret = call_action(action="query", feature_name=feature_name, query_context=query_context, query=query);
                outputs.append({"response": ret["response"], "time": time.time() - start_time});
            } except Exception as e {
                outputs.append({"response": str(e), "time": -1});
            }
        }
    }
    avg_time = sum([o["time"] for o in outputs]) / len(outputs);
    return {
        "outputs": outputs,
        "query": query,
        "feature_name": feature_name,
        "full_prompt": ret["full_prompt"],
        "avg_time": avg_time,
        "model_name": model_name
    };
}

glob llms = [
    "use config",
    "openai/gpt-4",
    "ollama/starling-lm:7b",
    "ollama/starling-lm:7b-alpha-q3_K_L",
    "ollama/starling-lm:7b-alpha-q2_K",
    "ollama/mistral:7b-instruct",
    "ollama/mistral:7b-instruct-q3_K_L",
    "ollama/zephyr:7b-beta",
    "ollama/zephyr:7b-beta-q3_K_L",
    "ollama/neural-chat:7b",
    "ollama/neural-chat:7b-v3.2-q3_K_L",
    "ollama/neural-chat:7b-v3.2-q2_K",
    "ollama/mistral:7b-instruct-q2_K",
    "ollama/mistral:7b-text",
    "ollama/mistral:7b-text-q3_K_L",
    "ollama/mistral:7b-text-q2_K",
    "ollama/orca-mini:3b",
    "ollama/llama2:7b-chat",
    "ollama/llama2:7b-chat-q3_K_L",
    "ollama/llama2:7b-chat-q2_K",
    "ollama/llama2:7b-text",
    "ollama/llama2:7b-text-q3_K_L",
    "ollama/llama2:7b-text-q2_K",
    "ollama/zephyr:7b-beta-q2_K",
    "ollama/stablelm-zephyr:3b",
    "ollama/stablelm-zephyr:3b-q3_K_L",
    "ollama/stablelm-zephyr:3b-q2_K",
    "ollama/falcon:7b-instruct",
    "ollama/falcon:7b-text",
    "ollama/orca2:7b",
    "ollama/orca2:7b-q3_K_L",
    "ollama/orca2:7b-q2_K",
    "ollama/openchat:7b-v3.5",
    "ollama/openchat:7b-v3.5-q3_K_L",
    "ollama/openchat:7b-v3.5-q2_K",
    "ollama/vicuna:7b",
    "ollama/vicuna:7b-q3_K_L",
    "ollama/vicuna:7b-q2_K"
];