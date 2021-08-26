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
  
  end
  end