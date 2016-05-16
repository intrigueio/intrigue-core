module Intrigue
  module Model
    class Logger
      include DataMapper::Resource

      property :id, Serial, :key => true
      property :full_log, Text, :length => 50000000, :default =>""
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.current_project }

      def self.current_project
        all(:project => Intrigue::Model::Project.current_project)
      end

      def log(message)
        _log "[ ] " << message
      end

      def log_debug(message)
        _log "[DEBUG] " << message
      end

      def log_good(message)
        _log "[+] " << message
      end

      def log_error(message)
        _log "[ERROR] " << message
      end

      def log_warning(message)
        _log "[WARN] " << message
      end

      def log_fatal(message)
        _log "[FATAL] " << message
      end

    private

      def _log(message)
        encoded_message = message.force_encoding('UTF-8')
        self.update(:full_log => "#{self.full_log}\n#{message}")

        # PRINT TO STANDARD OUT
        puts "#{message}"
      end

    end
end
end
