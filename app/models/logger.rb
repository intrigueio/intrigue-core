module Intrigue
  module Model
    class Logger < Sequel::Model
      plugin :serialization, :json
      plugin :validation_helpers

      one_to_one :task_result
      one_to_one :scan_result
      many_to_one :project

      def self.scope_by_project(name)
        named_project_id = Intrigue::Model::Project.first(:name => name).id
        where(:project_id => named_project_id)
      end

      def before_create
        self.location = Intrigue::Config::GlobalConfig.config["intrigue_task_log_location"] || "database"
        super
      end

      def validate
        super
      end

      def log(message)
        _log "[_] #{message}\n"
      end

      def log_debug(message)
        _log "[D] #{message}\n"
      end

      def log_good(message)
        _log "[+] #{message}\n"
      end

      def log_error(message)
        _log "[E] #{message}\n"
      end

      def log_warning(message)
        _log "[W] #{message}\n"
      end

      def log_fatal(message)
        _log "[F] #{message}\n"
      end

    private

      def _log(message)
        # if method is set to none, don't log anything
        return if location == "none"

        encoded_out = message.encode("UTF-8", {
                                :undef => :replace,
                                :invalid => :replace,
                                :replace => "?" })

        if location == "database"
          begin
            # any other value, log to the database
            update(:full_log => "#{full_log}#{encoded_out}")
            save
          rescue Sequel::DatabaseError => e
            puts "ERROR WRITING LOG FOR #{self}: #{e}"
          end
        elsif location == "file"
          File.open("#{$intrigue_basedir}/log/#{task_result.id}.log","a").puts "#{encoded_out}"
        else
          raise "Fatal! Unknown value for intrigue_task_log_location: #{intrigue_task_log_location}"
        end

      end

    end
end
end
