import os
import json
from datetime import datetime
def evaluate_responses(workers_data_dir, distribution_file, response_file):
    out_dataset = []
    criteria_set = ["clarity", "intelligence", "likability", "trustworthy", "overall", "feedback"]
    with open(distribution_file, "r") as file:
        distribution = json.load(file)
    with open(response_file, "r") as file:
        all_responses = json.load(file)
    for filename in os.listdir(workers_data_dir):
        file_path = os.path.join(workers_data_dir, filename)
        if os.path.isfile(file_path):
            with open(file_path, 'r') as file:
                worker_data = json.load(file)
            if "question_index" in worker_data and worker_data["question_index"]==5:
                curr_distribution_set=distribution.get(worker_data["question_set_id"],None)
                if curr_distribution_set is not None:
                    curr_worker_data_set = []
                    for i, (curr_dist,curr_worker_data) in enumerate(zip(curr_distribution_set,worker_data["evals"])):
                        model_a, response_a_id = curr_dist[1][0],curr_dist[2][0]
                        model_b, response_b_id = curr_dist[1][1],curr_dist[2][1]
                        response_a= all_responses.get(response_a_id,None)
                        response_b= all_responses.get(response_b_id,None)
                        criteria_data=[{criteria_set[i]:curr_worker_data['result'][i] for i in range(len(criteria_set))}]
                        curr_resp_contruct={"model_a":model_a,"response_a":response_a,"model_b":model_b,"response_b":response_b}
                        curr_resp_contruct.update(criteria_data[0])
                        if i == 0:
                            start_time = datetime.fromtimestamp(worker_data["start_time"])
                        end_time = datetime.fromtimestamp(curr_worker_data["time"])
                        curr_resp_contruct.update({"time_taken":(end_time-start_time).total_seconds()})
                        start_time=end_time
                        curr_worker_data_set.append(curr_resp_contruct)
                    out_dataset.append({worker_data["worker_id"]:curr_worker_data_set})
    return out_dataset