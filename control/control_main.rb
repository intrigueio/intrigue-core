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
  # start collection
  control.start_collect # TODO: loop until this is true

  sleep(config["sleep_interval"])
  _process_command
  tasks_left, seconds_elapsed = _get_progress





def _process_command
  begin
    lines = File.readlines("#{@core_dir}/tmp/commands.txt")
    command = lines.first&.strip
    success = false

    if command == "pause"
      puts "Pausing control."
      while true
        sleep 5
        lines2 = File.readlines("#{@core_dir}/tmp/commands.txt")
        command2 = lines2.first&.strip
        if command2 == "unpause"
          puts "UN-Pausing control."
          File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines2.drop(1)) }
          break
        end
      end
      success = true
    end
  
    if command == "unpause"
      puts "Got unpause command but we're not paused."
      success = true
    end

    if command == "cleanup"
      puts "Got cleanup command"
      _cleanup
      success = true
    end
    
    if command == "restart"
      puts "Got restart command"
      success = true
    end

    # if command executed successfully, remove it from list 
    if success
      File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines.drop(1)) }
    else
      File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines) }
    end
  rescue Errno::ENOENT
    return
  end

end # process command

