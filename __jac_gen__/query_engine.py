from __future__ import annotations
import json
from rag_engine import QueryEngine
from jaseci.utils.utils import logger
from jaseci.jsorc.live_actions import jaseci_action
engines = {}

@jaseci_action(act_group=['query_engine'], allow_remote=True)
def load_engine(config: dict, reload: bool=False) -> None:
    logger.info(f"Loading query engine: {config['engine_name']} for feature {config['feature_name']}")
    engine_name = config['engine_name']
    feature_name = config['feature_name']
    if engine_name not in engines:
        engines[feature_name] = QueryEngine.create(engine_name)
        engines[feature_name].load(config)
    elif reload:
        engines[feature_name].load(config)
    logger.info(f'Loaded query engine: {engine_name} for feature {feature_name}')

@jaseci_action(act_group=['query_engine'], allow_remote=True)
def save_engine(feature_name: str, path: str) -> None:
    logger.info(f'Saving query engine: {feature_name} to {path}')
    config = engines[feature_name].save()
    config['feature_name'] = feature_name
    with open(path, 'w') as f:
        json.dump(config, f, indent=2)
    logger.info(f'Saved query engine: {feature_name} to {path}')

@jaseci_action(act_group=['query_engine'], allow_remote=True)
def query(feature_name: str, query_context: str, query: str) -> None:
    logger.info(f'Querying {feature_name} with query: {query}')
    if feature_name not in engines:
        raise ValueError(f'Invalid feature name: {feature_name}')
    return engines[feature_name].query(payload={'query': query, 'context': query_context})