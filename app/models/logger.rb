module Intrigue
  module Model
    class Logger
      include DataMapper::Resource

      property :id, Serial, :key => true
      property :full_log, Text, :length => 50000000, :default =>""
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }

      def self.scope_by_project(id)
        all(:project => Intrigue::Model::Project.first(:name => name))
      end

      def log(message)
        _log "[#{id}][LOG] " << message
      end

      def log_debug(message)
        _log "[#{id}][DEBUG] " << message
      end

      def log_good(message)
        _log "[#{id}][+] " << message
      end

      def log_error(message)
        _log "[#{id}][ERROR] " << message
      end

      def log_warning(message)
        _log "[#{id}][WARN] " << message
      end

      def log_fatal(message)
        _log "[#{id}][FATAL] " << message
      end

    private

      def _log(message)
        encoded_message = message.force_encoding('UTF-8')
        attribute_set(:full_log, "#{@full_log}\n#{encoded_message}")

        # PRINT TO STANDARD OUT
        puts "#{encoded_message}"
      end

    end
end
end
