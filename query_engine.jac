import:py json;
import:py from rag_engine, QueryEngine;
import:py logging;

glob engines = {};

can load_engine(config: dict, reload: bool = False) -> None;
can save_engine(feature_name: str, path: str) -> None;
can query(feature_name: str, query_context: str, query:str);

# Loads the query engine
:can:load_engine(config: dict, reload: bool = False) -> None {
    logging.info(f"Loading query engine: {config['engine_name']} for feature {config['feature_name']}");

    engine_name = config['engine_name'];
    feature_name = config['feature_name'];
    if engine_name not in engines {
        engines[feature_name] = QueryEngine.create(engine_name);
        engines[feature_name].load(config);
    }
    elif reload {
        engines[feature_name].load(config);
    }

    logging.info(f"Loaded query engine: {engine_name} for feature {feature_name}");
}

# Saves the query engine
:can:save_engine(feature_name: str, path: str) -> None {
    logging.info(f"Saving query engine: {feature_name} to {path}");

    config = engines[feature_name].save();
    config["feature_name"] = feature_name;
    with open(path, "w") as f:
        json.dump(config, f, indent=2);

    logging.info(f"Saved query engine: {feature_name} to {path}");
}

# Queries the query engine
:can:query(feature_name: str, query_context: str, query:str) {
    logging.info(f"Querying {feature_name} with query: {query}");
    if feature_name not in engines {
        raise ValueError(f"Invalid feature name: {feature_name}");
    }
    return engines[feature_name].query(
        payload={"query": query, "context": query_context}
    );
}