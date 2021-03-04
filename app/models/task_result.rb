module Intrigue
module Core
module Model

  class TaskResult < Sequel::Model
    plugin :validation_helpers
    plugin :serialization, :json, :options, :handlers
    plugin :timestamps

    many_to_many :entities
    one_to_many :issues
    many_to_one :scan_result
    many_to_one :logger
    many_to_one :project
    many_to_one :base_entity, :class => :'Intrigue::Core::Model::Entity', :key => :base_entity_id

    include Intrigue::Core::ModelMixins::Handleable

    def self.scope_by_project(project_name)
      named_project = Intrigue::Core::Model::Project.first(:name => project_name)
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
      entities.paged_each(rows_per_fetch: 100){|e| return true if e.match?(entity) }
    false
    end

    # We should be able to get a corresponding task of our type
    # (TODO: should we store our actual task / configuration)
    def task
      Intrigue::TaskFactory.create_by_name(task_name)
    end

    def to_v1_api_hash(full=false)
      if full
        export_hash 
      else # just the light version
        {
          "id" => self.id,
          "name" =>  URI.escape(self.name),
          "task_name" => URI.escape(self.task_name),
          "timestamp_start" => self.timestamp_start,
          "timestamp_end" => self.timestamp_end,
          "options" => self.options,
          "complete" => self.complete,
        }
      end
    end

    def export_hash
      {
        "id" => self.id,
        "job_id" => self.job_id,
        "name" =>  URI.escape(self.name),
        "task_name" => URI.escape(self.task_name),
        "timestamp_start" => self.timestamp_start,
        "timestamp_end" => self.timestamp_end,
        "project" => self.project.name,
        "options" => self.options,
        "complete" => self.complete,
        "base_entity" =>  {:id => self.base_entity.id,
          :type => self.base_entity.type, :name => self.base_entity.name },
        "entities" => self.entities.uniq.map{ |e| {:id => e.id,
          :type => e.type, :name => e.name, :details => e.short_details } },
        "issues" => self.issues.uniq.map{ |e| {:id => e.id, :name => e.name, uri: e.uri } },
        "log" => self.get_log
      }
    end

    def export_csv
      self.entities.map{ |x| "#{x.export_csv}\n" }.join("")
    end

    def export_json
      export_hash.merge("generated_at" => "#{Time.now.utc}").to_json
    end

  end
  
end
end
end
