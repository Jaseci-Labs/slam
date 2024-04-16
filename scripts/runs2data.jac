import:py json;
import:py os;
import:py argparse;

can convert_run(run: str, prompt_disc: str) {
    responses_files = [f  for f in os.listdir(os.path.join("runs", run)) if f.endswith(".json")];
    data = {"run": run, "prompt_disc": prompt_disc, "outputs": {}};
    
    for responses_file in responses_files {
        with open(os.path.join("runs", run, responses_file), "r") as f {
            model_data = json.load(f);
            model_name = model_data["model_name"];
            prompt = model_data["full_prompt"];
            responses = [r["response"]  for r in model_data["outputs"]];
            data["outputs"][model_name] = responses;
            data["prompt"] = prompt if "prompt" not in data else data["prompt"];
        }
    }
    with open(os.path.join("data", f"{run}_responses"), "w") as f {
        json.dump(data, f, indent=4);
    }
}

with entry {
    parser = argparse.ArgumentParser(description="Convert the runs to data");
    parser.add_argument("-r", "--run_name", default="all", help="The run to convert");
    args = parser.parse_args();
    os.makedirs("data", exist_ok=True);
    runs = [f  for f in os.listdir("runs") if os.path.isdir(os.path.join("runs", f))];
    if args.run == "all" {
        for run in runs {
            prompt_disc_md = input(f"Provide the relative path to the prompt description markdown (.md) for run");
            prompt_disc = open(prompt_disc_md, "r").read();
            convert_run(run, prompt_disc);
        }
    } else {
        prompt_disc_md = input(f"Provide the relative path to the prompt description markdown (.md) for run");
        prompt_disc = open(prompt_disc_md, "r").read();
        convert_run(args.run, prompt_disc);
    }
}
