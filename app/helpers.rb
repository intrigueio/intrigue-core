
####
#### Helper method for starting a task run
####
def start_task_run(task_id, task_run_info)

  ###
  # XXX - Need to parse out the entity we want to pass to our tasks
  ###
  task_name = task_run_info["task"] ## Task name
  task_options = task_run_info["options"] ## || [{"name" => "count", "value" => 100 }]
  entity = task_run_info["entity"]  ## || {:type => "Host", :attributes => {:name => "8.8.8.8"}}
  webhook_uri = task_run_info["hook_uri"]

  ###
  # XXX - Create the task
  ###
  task = TaskFactory.create_by_name(task_name)

  unless entity
    entity = task.metadata[:example_entities].first
  end

  # Sending untrusted input in, so make sure we sanity check!
  jid = task.class.perform_async task_id, entity, task_options, ["webhook"], webhook_uri
end
