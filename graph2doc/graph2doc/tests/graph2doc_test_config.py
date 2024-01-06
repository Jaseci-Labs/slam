DESCRIPTION = (
    "These JSON describes a data graph for a productivity tool or todo list.\n"
    " Below are the possible node types:\n"
    " year, month, week, day: a year, month, week and day in the calendar\n"
    ' workette: an item in the todo list\n. An item can be off different types, further indicated by the "wtype" field\n'
    " ---------------------\n"
    " Below are the possible edge types:\n"
    " parent: If a parent edge is connecting item A and B, it means item B is part of item A. For example, B can be a subtask of A or B can be a task scheduled for day A.\n"
    " ---------------------\n"
    " For each node, the context dictionary contains the details of that node\n"
    ' Below are the fields in the "context" dictionary that you should pay attention to:\n'
    ' "name" field in the "context" is the name of the item.\n'
    ' "wtype" describes the type of item. workette is a task, workset is a task group, link is a link to a website or a file, and note is a piece of note.\n'
    ' In your response, refer to the item in a format like this -- item_type: item_name. For example, "task: finish homework", or "task group: chores" or "day: 2023-10-10"\n'
    ' "status" indicates the current status of this task: "open" means this task is not completed yet, "abandoned" means the user decided to cancel that task and "done" and "in_progress" are self explanatory.\n'
    ' "is_schedule_now" indicates if this task is scheduled to be considered today\n'
    ' "is_MIT", if True, means that this task is focused by the user and it is considered a high priority on that day. Do not use the word MIT in your response.\n'
    ' "is_ritual" indicates if this task is a recurring task and its content describes how the recurrence is configured. If "is_ritual" is not empty, make sure to describe it in your response\n'
    ' "note" are taken by the user and contain additional context and information for the task. Summarize the note content and include that in the task document on the same line of text.\n'
    ' "due_date" is an optional field that indicates when this task is due\n'
    " ignore all other fields, including color, is_active, expanded_children, order, focus_order, ritual_order, expanded_children, run_start, run_time, at, is_goal_progress_manual, goal_progress_percentage\n"
    " Make sure to always return three lines of text, where the first line describes the first node, the second line describes the second node and the third line describes the edge/relationship\n"
)
EXAMPLES = [
    {
        "jsons": [
            {
                "name": "workette",
                "kind": "node",
                "jid": "urn:uuid:47f7cc0f-25e3-46c9-98d9-3c0467bb96e0",
                "j_timestamp": "2023-10-06T14:53:51.327997",
                "j_type": "node",
                "context": {
                    "name": "get fit",
                    "order": [],
                    "due_date": None,
                    "status": "done",
                    "snooze_till": None,
                    "color": "#8d8d95",
                    "links": None,
                    "expanded_children": None,
                    "note_last_updated": None,
                    "wtype": "workset",
                    "note": "- lose weight\n- get stronger\n- get faster",
                    "is_MIT": False,
                    "is_ritual": None,
                    "is_active": None,
                    "recurring_order": [],
                    "run_start": None,
                    "run_time": None,
                    "highlight_type": [],
                    "focus_order": [],
                    "ritual_order": [],
                    "ritual_streak": 0,
                    "ritual_tracking": [],
                    "ritual_history": [],
                    "at": ["day", "2023-10-11T00:00:00"],
                    "is_snoozed": False,
                    "is_active_ritual": False,
                    "is_scheduled_now": True,
                    "is_expired_ritual": False,
                    "is_goal_progress_manual": False,
                    "goal_progress_percentage": 0,
                },
            },
            {
                "from_node_id": "urn:uuid:47f7cc0f-25e3-46c9-98d9-3c0467bb96e0",
                "to_node_id": "urn:uuid:d270485f-95b0-4a08-b052-c3c24d876cdc",
                "context": {},
                "name": "parent",
                "kind": "edge",
                "jid": "urn:uuid:236b0ff2-8211-472d-bb9c-d4d0b71aca18",
                "j_timestamp": "2023-10-06T14:53:51.328279",
                "j_type": "edge",
            },
            {
                "name": "workette",
                "kind": "node",
                "jid": "urn:uuid:d270485f-95b0-4a08-b052-c3c24d876cdc",
                "j_timestamp": "2023-10-06T14:53:51.328098",
                "j_type": "node",
                "context": {
                    "name": "do cardio",
                    "order": [],
                    "due_date": None,
                    "status": "open",
                    "snooze_till": None,
                    "color": None,
                    "links": None,
                    "expanded_children": None,
                    "note_last_updated": None,
                    "wtype": "workette",
                    "note": "",
                    "is_MIT": True,
                    "is_ritual": None,
                    "is_active": None,
                    "recurring_order": [],
                    "run_start": None,
                    "run_time": None,
                    "highlight_type": [],
                    "focus_order": [],
                    "ritual_order": [],
                    "ritual_streak": 0,
                    "ritual_tracking": [],
                    "ritual_history": [],
                    "at": ["day", "2023-10-11T00:00:00"],
                    "is_snoozed": False,
                    "is_active_ritual": False,
                    "is_scheduled_now": True,
                    "is_expired_ritual": False,
                    "is_goal_progress_manual": False,
                    "goal_progress_percentage": 0,
                },
            },
        ],
        "docs": [
            "Task group: get fit is open and has notes that summarize to be more healthy and fit.",
            "Task: do cardio has been completed and is a focused priority task.",
            "Task: do cardio is a subtask of task group: get fit.",
        ],
    },
    {
        "jsons": [
            {
                "name": "day",
                "kind": "node",
                "jid": "urn:uuid:d6863a05-25d3-4d51-97bf-541339b3bebc",
                "j_timestamp": "2023-10-11T18:48:38.488495",
                "j_type": "node",
                "context": {
                    "day": "2023-10-11T00:00:00",
                    "note": None,
                    "order": [],
                    "focus_order": [],
                    "ritual_order": [],
                    "expanded_children": [],
                    "show_hidden_items": None,
                    "focusR": None,
                    "log": None,
                    "highlevel_groups": None,
                    "note_last_updated": None,
                    "recurring_order": [
                        "urn:uuid:c0018b64-a664-4e80-8475-c052cece602a",
                        "urn:uuid:c2ee5113-f3a5-46e9-bc8a-50ae95a493f5",
                    ],
                    "ll_version": "0.8.1",
                    "item_filters": None,
                    "ritual_tracking": [],
                },
            },
            {
                "from_node_id": "urn:uuid:d6863a05-25d3-4d51-97bf-541339b3bebc",
                "to_node_id": "urn:uuid:6cb08433-1af2-4bdb-8451-9fbebebeaf65",
                "context": {},
                "name": "parent",
                "kind": "edge",
                "jid": "urn:uuid:036500f0-105c-4d63-80fc-11088afffb6a",
                "j_timestamp": "2023-10-11T18:48:38.490389",
                "j_type": "edge",
            },
            {
                "name": "workette",
                "kind": "node",
                "jid": "urn:uuid:6cb08433-1af2-4bdb-8451-9fbebebeaf65",
                "j_timestamp": "2023-10-11T18:48:38.488538",
                "j_type": "node",
                "context": {
                    "name": "Plan for the week",
                    "order": [],
                    "due_date": None,
                    "status": "open",
                    "snooze_till": "",
                    "color": "",
                    "links": [],
                    "expanded_children": "",
                    "note_last_updated": None,
                    "wtype": "",
                    "note": "",
                    "is_MIT": True,
                    "is_ritual": {
                        "frequency": "WEEK",
                        "byDayOfWeek": [False, False, False, False, False, False, 1],
                        "interval": 1,
                        "start": "2023-02-03T00:00:00",
                    },
                    "is_active": True,
                    "recurring_order": [],
                    "run_start": 1606680738.079,
                    "run_time": 0,
                    "highlight_type": [],
                    "focus_order": [],
                    "ritual_order": [],
                    "ritual_streak": 0,
                    "ritual_tracking": [],
                    "ritual_history": [],
                    "at": ["day", "2023-10-11T00:00:00"],
                    "is_snoozed": False,
                    "is_active_ritual": False,
                    "is_scheduled_now": False,
                    "is_expired_ritual": False,
                    "is_goal_progress_manual": False,
                    "goal_progress_percentage": 0,
                },
            },
        ],
        "docs": [
            "Day: 2023-10-11 is a day",
            "Task: Plan for the week is a open task and is a ritual that occurs every week on Sundays",
            "Task: Plan for the week is a child of day: 2023-10-11",
        ],
    },
]

FIELDS = [
    "name",
    "due_date",
    "snooze_till",
    "workette_type",
    #    "note",
    "is_MIT",
    "is_ritual",
    "ritual_streak",
    "at",
]
