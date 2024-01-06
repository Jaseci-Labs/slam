from .graph2doc import Graph2Doc


class Graph2DocRules(Graph2Doc):
    """
    Convert subgraphs to a document using rules
    """

    def __init__(self) -> None:
        super().__init__()

    def convert_type(self, obj, nmap):
        return nmap.get(obj["name"], obj["name"])

    def convert_name(self, obj, ent_keys, nmap):
        try:
            return obj["context"][ent_keys[obj["name"]]]
        except:
            return obj["name"]

    def gen_doc_entity(self, entity, entity_keys={}, embed_props={}, name_mappings={}):
        """
        Given an entity, generate a document (natural language)
        Entity is a json that looks like this
        {
          "name": "workette",
          "kind": "node",
          "jid": "urn:uuid:47f7cc0f-25e3-46c9-98d9-3c0467bb96e0",
          "j_timestamp": "2023-10-06T14:53:51.327997",
          "j_type": "node",
          "context": {
            "name": "get fit",
            "notes": null
          }
        }
        """
        document = ""
        node_type = name_mappings.get(entity["name"], entity["name"])
        try:
            node_name = entity["context"][entity_keys[entity["name"]]]
        except:
            node_name = entity["name"]

        document += f"{node_name} is a {node_type}"
        for prop in embed_props.get(entity["name"], []):
            prop_name = name_mappings.get(prop, prop)
            document += f', with {prop_name} as {entity["context"][prop]}'

        return document

    def gen_doc_rel(self, triplet, entity_keys={}, embed_props={}, name_mappings={}):
        """
        Given a triplet, generate a document describing the relationship.
        A triplet looks like this
        {
          "name": "workette",
          "kind": "node",
          "jid": "urn:uuid:47f7cc0f-25e3-46c9-98d9-3c0467bb96e0",
          "j_timestamp": "2023-10-06T14:53:51.327997",
          "j_type": "node",
          "context": {
            "name": "get fit",
            "notes": null
          }
        },
        {
          "from_node_id": "urn:uuid:47f7cc0f-25e3-46c9-98d9-3c0467bb96e0",
          "to_node_id": "urn:uuid:d270485f-95b0-4a08-b052-c3c24d876cdc",
          "context": {},
          "name": "parent",
          "kind": "edge",
          "jid": "urn:uuid:236b0ff2-8211-472d-bb9c-d4d0b71aca18",
          "j_timestamp": "2023-10-06T14:53:51.328279",
          "j_type": "edge"
        },
        {
          "name": "workette",
          "kind": "node",
          "jid": "urn:uuid:d270485f-95b0-4a08-b052-c3c24d876cdc",
          "j_timestamp": "2023-10-06T14:53:51.328098",
          "j_type": "node",
          "context": {
            "name": "do cardio daily",
            "notes": null
          }
        }
        """
        subject, predicate, object_ = triplet

        document = (
            f"The {self.convert_type(subject, name_mappings)} {self.convert_name(subject, entity_keys, name_mappings)}"  # subject
            f" is {self.convert_type(predicate, name_mappings)}"  # predicate
            f" {self.convert_type(object_, name_mappings)} {self.convert_name(object_, entity_keys, name_mappings)}"  # object
        )
        return document

    def compose_with_subgraph(
        self,
        chains,
        entity_keys={},
        embed_props={},
        name_mappings={},
    ):
        """
        Query the LLM with subgraph.
        This will convert the set of triplets to natural language documents and incorporate into the prompt.
        master: user's master jid
        chains: list of triplets
        prompt: the prompt to query with
        query: the actual question
        """
        documents, _ = self.triplets_to_documents(
            chains=chains,
            entity_keys=entity_keys,
            embed_props=embed_props,
            name_mappings=name_mappings,
        )
        return documents

    def convert(
        self,
        subgraphs,
        entity_keys={},
        embed_props={},
        name_mappings={},
    ):
        """
        Convert a list of triplets to a list of natural language documents.
        """
        documents = []
        ids = []
        for chain in subgraphs:
            # TODO: support other types of subgraphs: longer chains, multiple children etc.
            # For now, we just deal with triplets
            subject, predicate, object_ = chain

            subject_doc = self.gen_doc_entity(
                entity=subject,
                entity_keys=entity_keys,
                embed_props=embed_props,
                name_mappings=name_mappings,
            )
            object_doc = self.gen_doc_entity(
                entity=object_,
                entity_keys=entity_keys,
                embed_props=embed_props,
                name_mappings=name_mappings,
            )
            predicate_doc = self.gen_doc_rel(
                triplet=chain,
                entity_keys=entity_keys,
                embed_props=embed_props,
                name_mappings=name_mappings,
            )
            if subject["jid"] not in ids:
                documents.append(subject_doc)
                ids.append(subject["jid"])

            if object_["jid"] not in ids:
                documents.append(object_doc)
                ids.append(object_["jid"])

            if predicate["jid"] not in ids:
                documents.append(predicate_doc)
                ids.append(predicate["jid"])

        return documents, ids
