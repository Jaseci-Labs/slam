from graph2doc.graph2doc import Graph2Doc


class Graph2DocCustomMyca(Graph2Doc):
    """
    Custom Graph2Doc instructions for Myca graph
    """

    def __init__(self) -> None:
        super().__init__()
        self.llm = "gpt-3.5-turbo-0613"

    def gen_doc_workette(self, node):
        """
        Given a workette, generate a natural language document describing it
        """
        doc = ""

        # Workette type
        ctx = node["context"]
        if ctx["wtype"] == "workset":
            doc += f"\"{ctx['name']}\" is a task group."
        elif ctx["wtype"] == "workette":
            doc += f"\"{ctx['name']}\" is a task."
        elif ctx["wtype"] == "link":
            doc += f"\"{ctx['name']}\" is a link."
        elif ctx["wtype"] == "note":
            doc += f"\"{ctx['name']}\" is a note."
        else:
            # Fall back as task
            doc += f"\"{ctx['name']}\" is a task."

        # Ritual information
        if ctx["is_ritual"]:
            ritual_config = ctx["is_ritual"]
            if ritual_config["frequency"] == "DAYS" or (
                ritual_config["frequency"] in ["WEEKS", "WEEK"]
                and all(ritual_config["byDayOfWeek"])
            ):
                doc += f" It is a daily recurring {'ritual' if ritual_config.get('ritual_flag', True) else 'task'}"
                if "start" in ritual_config:
                    doc += f" starting from {ritual_config['start']}."
                else:
                    doc += "."
            elif ritual_config["frequency"] in ["WEEKS", "WEEK"]:
                day_of_week = [
                    "Monday",
                    "Tuesday",
                    "Wednesday",
                    "Thursday",
                    "Friday",
                    "Saturday",
                    "Sunday",
                ]
                occuring_days = [
                    day_of_week[i] if ritual_config["byDayOfWeek"][i] else None
                    for i in range(7)
                ]
                occuring_days = [day for day in occuring_days if day]
                doc += f" It is a weekly recurring {'ritual' if ritual_config.get('ritual_flag', True) else 'task'}"
                doc += f" that is scheduled to occur on {', '.join(occuring_days)}"
                if "start" in ritual_config:
                    doc += f" starting from {ritual_config['start'].split('T')[0]}."
                else:
                    doc += "."
            elif ritual_config["frequency"] == "MONTHS":
                doc += f" It is a monthly recurring {'ritual' if ritual_config.get('ritual_flag', True) else 'task'}"
                if "start" in ritual_config:
                    doc += (
                        " starting from " + ritual_config["start"].split("T")[0] + "."
                    )
                else:
                    doc += "."

            # ritual_streak
            doc += (
                " It has been completed "
                + str(ctx["ritual_streak"])
                + " times in a row."
            )

        # Due date
        if ctx["due_date"]:
            doc += " It is due on " + ctx["due_date"] + "."

        # Snooze date
        if ctx["snooze_till"]:
            doc += " It was snoozed until " + ctx["snooze_till"] + "."

        if ctx["status"] == "open":
            doc += " It is currently open."
        elif ctx["status"] == "done":
            doc += " It is currently completed."
        elif ctx["status"] == "running":
            doc += " It is currently in progress."
        elif ctx["status"] == "canceled":
            doc += " It is currently abandoned."

        # focused (is_MIT)
        if ctx["is_MIT"]:
            doc += " It is a focused high priority task."

        def _summarize_notes(ctx):
            messages = [
                {
                    "role": "user",
                    "content": f"Below is some notes taken by a user for their todo list task called \"{ctx['name']}\". Generate a short summary of the notes. Keep the summary under 50 words. Do not start with \"Here is the summary\" or \"Based on the user's nots\" or anything along those lines. Here are the notes:\n{ctx['note']}. Summary:\n",
                },
            ]
            res = openai.ChatCompletion.create(
                model=self.llm, messages=messages, temperature=0.5
            )
            responses = [c.message for c in res.choices]
            return responses[0]["content"]

        # Note:
        if ctx["note"]:
            # summarize the notes if its longer than 50 words
            if len(ctx["note"]) < 50 * 6:
                doc += " It has the following notes " + ctx["note"] + "."
            # else:
            #     doc += (
            #         " It has the following notes "
            #         + _summarize_notes(ctx)
            #         + "."
            #     )
        return doc

    def gen_doc_day(self, node):
        """
        Given a day node, return a natural language document describing it
        """
        return ""

    def gen_doc_week(self, week_node):
        pass

    def gen_doc_month(self, month_node):
        pass

    def gen_doc_year(self, year_node):
        pass

    def gen_doc_goal(self, goal_node):
        """
        Given a goal node, return a natural language document describing it
        """
        pass

    def gen_doc_rel_workette_parent(self, wkt_parent, wkt_child, parent_edge):
        """
        wkt -[parent]-> wkt
        """
        doc = ""
        if wkt_parent["context"]["wtype"] == "workset":
            doc += f"Task group \"{wkt_parent['context']['name']}\""
        elif wkt_parent["context"]["wtype"] == "workette":
            doc += f"Task \"{wkt_parent['context']['name']}\""
        elif wkt_parent["context"]["wtype"] == "note":
            doc += f"Note \"{wkt_parent['context']['name']}\""
        elif wkt_parent["context"]["wtype"] == "link":
            doc += f"Link \"{wkt_parent['context']['name']}\""

        if wkt_child["context"]["wtype"] == "workset":
            doc += f" contains the task group \"{wkt_child['context']['name']}\""
        elif wkt_child["context"]["wtype"] == "workette":
            doc += f" has the sub task \"{wkt_child['context']['name']}\""
        elif wkt_child["context"]["wtype"] == "note":
            doc += f" contains the note \"{wkt_child['context']['name']}\""
        elif wkt_child["context"]["wtype"] == "link":
            doc += f" contains the link \"{wkt_child['context']['name']}\""

        return doc

    def gen_doc_rel_day_workette(self, day_node, workette_node, edge):
        """
        day --> wkt
        """
        pass

    def gen_doc_node(self, node):
        doc = ""
        if node["name"] == "workette" and node["context"]["wtype"] == "goal":
            doc = self.gen_doc_goal(node)
        elif node["name"] == "workette":
            doc = self.gen_doc_workette(node)
        elif node["name"] == "day":
            doc = self.gen_doc_day(node)
        elif node["name"] == "week":
            doc = self.gen_doc_week(node)
        elif node["name"] == "month":
            doc = self.gen_doc_month(node)
        elif node["name"] == "year":
            doc = self.gen_doc_year(node)
        return doc

    def gen_doc_edge(self, node1, node2, edge):
        doc = ""
        if (
            node1["name"] == "workette"
            and node2["name"] == "workette"
            and edge["name"] == "parent"
        ):
            doc = self.gen_doc_rel_workette_parent(node1, node2, edge)

        return doc

    def convert(self, subgraphs, llm="gpt-3.5-turbo-0613"):
        documents = []
        ids = []
        for chain in subgraphs:
            # chain = (node, edge, node)
            subject, predicate, object_ = chain
            subject_doc = self.gen_doc_node(subject)
            object_doc = self.gen_doc_node(object_)
            predicate_doc = self.gen_doc_edge(subject, object_, predicate)

            if subject_doc != "" and subject["jid"] not in ids:
                documents.append(subject_doc)
                ids.append(subject["jid"])

            if object_doc != "" and object_["jid"] not in ids:
                documents.append(object_doc)
                ids.append(object_["jid"])

            if predicate_doc != "" and predicate["jid"] not in ids:
                documents.append(predicate_doc)
                ids.append(predicate["jid"])

        return documents, ids
