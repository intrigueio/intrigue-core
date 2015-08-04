class IntrigueApp < Sinatra::Base

  ####
  #### Helper method for starting a task run
  ####
  def start_task_run(task_id, task_run_info)

    ###
    # Need to parse out the entity we want to pass to our tasks
    ###
    task_name = task_run_info["task"]       ## Task name
    task_options = task_run_info["options"] ## || [{"name" => "count", "value" => 100 }]
    entity = task_run_info["entity"]        ## || {:type => "Host", :attributes => {:name => "8.8.8.8"}}
    webhook_uri = task_run_info["hook_uri"]

    ###
    # Create the task
    ###
    task =  Intrigue::TaskFactory.create_by_name(task_name)

    unless entity
      entity = task.metadata[:example_entities].first
    end

    # note, this input is untrusted.
    jid = task.class.perform_async task_id, entity, task_options, ["webhook"], "#{$intrigue_server_uri}/v1/task_runs/#{task_id}"

  end

  ####
  #### Helper method for starting a scan run
  ####
  def start_scan(scan_id, entity, name, depth)

    ###
    # Create the scan
    ###
    scan = Intrigue::Scanner::SimpleScan.new

    # note, this input is untrusted.
    jid = scan.class.perform_async scan_id, entity, name, depth
  end

end
