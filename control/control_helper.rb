## Helper methods
module Intrigue
  module ControlHelpers
  
    def current_time_string
      Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    end
  
    def _log(message)
      puts "[ ] #{current_time_string} #{message}"
      log_to_file "[ ] #{message}"
    end
  
    def _log_error(message)
      puts "[-] #{current_time_string} #{message}"
      log_to_file "[-] #{message}"
    end
  
    def _log_good(message)
      puts "[+] #{current_time_string} #{message}"
      log_to_file "[+] #{message}"
    end
  
    def log_to_file(message)
      return unless @@logfile
      #return unless File.exist? @logfile
      File.open(@@logfile,"a"){|f| f.puts message }
    end
  
    def set_notifier(slack_hook)
      @@slack_notifier = Intrigue::Notifier::Slack.new({"slack_hook_url" => slack_hook})
    end

    def set_logfile(logfile)
      @@logfile = logfile
    end
    
    def _log_notifier(message)
      @@slack_notifier&.notify("#{message}\n")
    end

    def check_env_vars(vars)
      vars.each do |var|
        if ENV[var].nil?
          puts "Environment variable #{var} missing! Cannot start! Dying..:("
          exit(-1)
        end
      end
    end

    def process_command(control=nil)
      command = _read_command
      success = false

      puts "Processing command: #{command}"
    
      if command == "pause"
        puts "Control paused."
        sleep 10
        _process_command
        success = true
      end
  
      if command == "abort"
        puts "Got abort command"
        control._cleanup
        success = true
      end
      
      if command == "finish"
        puts "Got finish command"
        control._clear_queues
        success = true
      end

      if command == "test"
        success = true
      end

      if success
        _delete_command
      end
    end

    def _read_command
      begin
        # ugly hack, should not hardcode core directory
        lines = File.readlines("/home/ubuntu/core/tmp/commands.txt")
        command = lines.first&.strip
        return command
      rescue Errno::ENOENT
        return nil
      end
    end

    def _delete_command
      begin
        lines = File.readlines("/home/ubuntu/core/tmp/commands.txt")
        File.open("/home/ubuntu/core/tmp/commands.txt", 'w') {|file| file.puts(lines.drop(1)) }
        return true
      rescue Errno::ENOENT
        return nil
      end
    end
    
  end
end
