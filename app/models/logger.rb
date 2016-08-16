module Intrigue
  module Model
    class Logger
      include DataMapper::Resource

      property :id, Serial, :key => true
      property :location, String
      property :full_log, Text, :length => 50000000, :default =>""
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }

      def initialize(params)
        global_config = Intrigue::Config::GlobalConfig.new
        attribute_set(:location, global_config.config["intrigue_task_log_location"] || "database")
        save
      end

      def self.scope_by_project(name)
        all(:project => Intrigue::Model::Project.first(:name => name))
      end

      def retrieve
        if @location == "database"
          return @full_log
        elsif @location == "file"
          File.open("#{$intrigue_basedir}/log/#{@id}.log","r").read
        elsif @location == "none"
          # not doing anything
        else
          raise "Unknown log location configuration: #{@location}. Please check the global config: intrigue_task_log_location"
        end
      end


      def log(message)
        _log "[#{id}][ ] " << message
      end

      def log_debug(message)
        _log "[#{id}][D] " << message
      end

      def log_good(message)
        _log "[#{id}][+] " << message
      end

      def log_error(message)
        _log "[#{id}][D] " << message
      end

      def log_warning(message)
        _log "[#{id}][W] " << message
      end

      def log_fatal(message)
        _log "[#{id}][F] " << message
      end


    private

      def _log(message)
        encoded_message = _encode_string(message)

        if @location == "database"
          attribute_set(:full_log, "#{@full_log}\n#{encoded_message}")
        elsif @location == "file"
          File.open("#{$intrigue_basedir}/log/#{@id}.log","a+").write("#{encoded_message}\n")
        elsif @location == "none"
          # not doing anything
        else
          raise "Unknown log location configuration: #{@location}. Please check the global config: intrigue_task_log_location"
        end

      end

      def _encode_string(string)
        string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
      end

    end
end
end
