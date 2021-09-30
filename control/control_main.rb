require './control/control_app.rb'

# the necessary environment variables to function properly
env_vars = [
  "INTRIGUE_DIRECTORY",
  "ENGINE_API_KEY",
  "APP_ENV",
  "SLACK_HOOK_URL",
  "ENGINE_SOURCE",
  "MIN_PRIORITY",
  "MAX_PRIORITY",
  "PLATFORM_INGRESS",
  "LOAD_GLOBAL_ENTITIES",
  "APP_HOSTNAME",
  "APP_PORT",
  "APP_PROTOCOL",
  "APP_HANDLER"
]

# check if configuration parameters are present
Intrigue::ControlHelpers::check_env_vars(env_vars)

# create configuration for intrigue control
config = {
  "logfile" => "#{ENV["INTRIGUE_DIRECTORY"]}/log/control-output.log",
  "sleep_interval" => 15,
  "max_seconds"=> 777600,
  "checkin_seconds" => 30,
  "handler" => "#{ENV["APP_HANDLER"]}",
  "app_hostname" => "#{ENV["APP_HOSTNAME"]}:#{ENV["APP_PORT"]}",
  "app_protocol" => "#{ENV["APP_PROTOCOL"]}",
  "app_key" => "#{ENV["ENGINE_API_KEY"]}",
  "slack_hook_url" => "#{ENV["SLACK_HOOK_URL"]}",
  "min_priority" => "#{ENV["MIN_PRIORITY"]}",
  "max_priority" => "#{ENV["MAX_PRIORITY"]}",
  "platform_ingress" => ("#{ENV["PLATFORM_INGRESS"]}" == "true"),
  "load_global_entities" => false,# ("#{ENV["LOAD_GLOBAL_ENTITIES"]}" == "true")
  "core_dir" => "#{ENV["INTRIGUE_DIRECTORY"]}",
  "engine_source" => "#{ENV["ENGINE_SOURCE"]}"
}

# initialize control
control = Intrigue::Control::Intrigueio.new(config)

while true
  # process command in case we're asked to do anything before starting a new collection
  process_command

  # start scanning a collection
  current_collection = control.run
  unless current_collection
    # if we fail to start a colleciton run, we sleep randomly to not waste cpu because there may not be anything to collect atm
    wait_time = rand(100)
    puts "Unable to start collection run. Sleeping... #{wait_time}"
    sleep wait_time
    next
  end
  
  _log "Starting to scan collection: #{current_collection}"
  # loop until we're done or the maximum duration is achieved
  while control.tasks_left.positive? && control.seconds_elapsed < config["max_seconds"]
    sleep(config["sleep_interval"])
    _log control.get_progress
    control.send_heartbeat
    process_command(control)
  end

  # ok we're done. upload results
  control.send_finished_project

end