module Intrigue
  module Core
    module Model
      class Logger < Sequel::Model
        plugin :serialization, :json
        plugin :validation_helpers
        plugin :timestamps
        
        one_to_one :task_result
        one_to_one :scan_result
        many_to_one :project

        def before_create
          self.location = Intrigue::Core::System::Config.config["intrigue_task_log_location"] || "none"
          super
        end

        @@log_level = Intrigue::Core::System::Config.config['intrigue_task_log_level'] || 'fatal'
        @@log_level = @@log_level.downcase

        def self.scope_by_project(name)
          named_project_id = Intrigue::Core::Model::Project.first(name: name).id
          where(project_id: named_project_id)
        end

        def validate
          super
        end

        def log(message)
          _log "[_] #{message}\n" if @@log_level == 'verbose'
        end

        def log_debug(message)
          p ['verbose', 'debug'].include? @@log_level
          _log "[D] #{message}\n" if ['verbose', 'debug'].include? @@log_level
        end

        def log_good(message)
          _log "[+] #{message}\n" if ['verbose', 'good', 'debug'].include? @@log_level
        end

        def log_error(message)
          _log "[E] #{message}\n" if ['verbose', 'good', 'debug', 'warning', 'error'].include? @@log_level
        end

        def log_warning(message)
          _log "[W] #{message}\n" if ['verbose', 'good', 'debug', 'warning'].include? @@log_level
        end

        def log_fatal(message)
          _log "[F] #{message}\n" if ['verbose', 'good', 'debug', 'warning', 'error', 'fatal'].include? @@log_level
        end

        private

        def _log(message)
          # if method is set to none, don't log anything
          return if location == 'none'

          encoded_out = message.sanitize_unicode

          if location == 'database'
            begin
              # any other value, log to the database
              update(full_log: "#{full_log}#{encoded_out}")
              save_changes
            rescue Sequel::DatabaseError => e
              puts "ERROR WRITING LOG FOR #{self}: #{e}"
            end

          elsif location == 'file'
            File.open("#{$intrigue_basedir}/log/#{task_result.id}.log", 'a') { |f| f.puts encoded_out.to_s; }
          else
            raise "Fatal! Unknown value for intrigue_task_log_location: #{intrigue_task_log_location}"
          end
        end
        
      end
    end
  end
end
