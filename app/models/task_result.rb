module Intrigue
  module Model
    class TaskResult < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      many_to_many :entities
      many_to_one :scan_result
      many_to_one :logger
      many_to_one :project
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      include Intrigue::Model::Mixins::Handleable

      def self.scope_by_project(project_name)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(:project => named_project)
      end

      def validate
        super
      end

      def start(requested_queue=nil)

        task_class = Intrigue::TaskFactory.create_by_name(task_name).class
        forced_queue = task_class.metadata[:queue]

        sidekiq_client = Sidekiq::Client.new

        sjid = sidekiq_client.push({
          "class" => task_class.to_s,
          "queue" => forced_queue || requested_queue || "task",
          "retry" => true,
          "args" => [id]
        })
        self.job_id = sjid
        save_changes

      sjid
      end

      def cancel!
        unless complete
          self.cancelled = true
          save_changes
        end
      end

      # EXPOSE LOGGING METHODS
      def log(message)
        logger.log("#{message}")
      end

      def log_good(message)
        logger.log_good("#{message}")
      end

      def log_error(message)
        logger.log_error("#{message}")
      end

      def log_fatal(message)
        logger.log_fatal("#{message}")
      end

      def get_log
        if logger.location == "database"
          out = logger.full_log
        elsif logger.location == "file"
          logfile = "#{$intrigue_basedir}/log/#{self.id}.log"
          if File.exist? logfile
            out = File.open(logfile,"r").read
          else
            out = "Missing Logfile: #{logfile}"
          end
        elsif location == "none"
          out = "No log"
        else
          raise "Invalid log location"
        end
      out
      end
      # END EXPOSE LOGGING METHODS

      def machine
        return scan_result.machine if scan_result
      nil
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        entities.each {|e| return true if e.match?(entity) }
      false
      end

      # We should be able to get a corresponding task of our type
      # (TODO: should we store our actual task / configuration)
      def task
        Intrigue::TaskFactory.create_by_name(task_name)
      end

      def export_hash
        {
          "id" => id,
          "job_id" => job_id,
          "name" =>  URI.escape(name),
          "task_name" => URI.escape(task_name),
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "project" => project.name,
          "options" => options,
          "complete" => complete,
          "base_entity" => base_entity.export_hash,
          "entities" => entities.uniq.map{ |e| {:id => e.id,
            :type => e.type, :name => e.name, :details => e.short_details } },
          "log" => get_log
        }
      end

      def export_csv
        self.entities.map{ |x| "#{x.export_csv}\n" }.join("")
      end

      def export_json
        export_hash.merge("generated_at" => "#{DateTime.now}").to_json
      end

    end
  end
end
