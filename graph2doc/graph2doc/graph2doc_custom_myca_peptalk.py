from graph2doc.graph2doc import Graph2Doc


class Graph2DocCustomMycaPeptalk(Graph2Doc):
    def __init__(self) -> None:
        super().__init__()

    def convert(self, subgraphs):
        # subgraphs has three elements
        # prev_day: yesterday's summary items
        # today: today's plan page (full day hierachy)
        # week: week and weekly goals
        today_sbg = subgraphs["today"]
        prev_day_sbg = subgraphs["prev_day"]
        week_sbg = subgraphs["week"]

        # This will return just one single document
        # This is just a list of strings that will be concatneated with newlines
        documents = []

        # some preamble
        documents.append(f'Today is {today_sbg[0][0]["context"]["day"].split("T")[0]}.')

        # generate document for last day's summary
        doc = "\n"
        doc += f'The last day I logged in was {prev_day_sbg[0][0]["context"]["day"].split("T")[0]} and I completed the following tasks on that day:\n'
        tasks = []

        for chain in prev_day_sbg:
            subject, predicate, object_ = chain
            if (
                object_["context"]["wtype"] == "workette"
                and object_["context"]["status"] == "done"
            ):
                tasks.append(object_["context"]["name"])

        doc += "\n".join(tasks)
        documents.append(doc)

        # generate document for today's focus
        doc = "\n"
        doc += "Here are today's focused tasks. These are tasks that I think are important:\n"
        tasks = []
        task_ids = []
        for chain in today_sbg:
            subject, predicate, object_ = chain
            if (
                object_["context"]["wtype"] == "workette"
                and object_["context"]["is_MIT"]
                and object_["context"]["is_scheduled_now"]
                and object_["jid"] not in task_ids
            ):
                tasks.append(object_["context"]["name"])
                task_ids.append(object_["jid"])

        doc += "\n".join(tasks)
        documents.append(doc)

        # generate document for today's rituals
        doc = "\n"
        doc += "Here are the rituals that are scheduled for today. These are recurring tasks that help me build and maintain good habits or work/life responsibilities that happen regularly:\n"
        tasks = []
        task_ids = []
        for chain in today_sbg:
            subject, predicate, object_ = chain
            if (
                object_["context"]["wtype"] == "workette"
                and object_["context"]["is_ritual"]
                and object_["context"]["is_scheduled_now"]
                and object_["jid"] not in task_ids
            ):
                tasks.append(object_["context"]["name"])
                task_ids.append(object_["jid"])
        doc += "\n".join(tasks)
        documents.append(doc)

        # generate documents for this week's goals
        if len(week_sbg) > 0:
            doc = "\n"
            doc += "I have also set the following goals for myself for this week. These are overarching objectives I want to accomplish in this week:\n"
            goals = []
            for chain in week_sbg:
                subject, predicate, object_ = chain
                if (
                    object_["context"]["wtype"] == "goal"
                    and object_["context"]["status"] == "open"
                ):
                    goals.append(object_["context"]["name"])

            doc += "\n".join(goals)
            documents.append(doc)

        return documents, []
