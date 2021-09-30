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

    def _process_command(control=nil)
      begin
        lines = File.readlines("#{@core_dir}/tmp/commands.txt")
        command = lines.first&.strip
        success = false
    
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
    
  end
end
