module Intrigue
  module Model
    class ScanResult < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      many_to_one :logger
      many_to_one :project
      one_to_many :task_results
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def validate
        super
        #validates_unique([:name, :project_id, :depth])
      end

      def start(queue)

        # Start our first task
        self.job_id = task_results.first.start(queue)
        save

      job_id
      end

      def log
        logger.full_log
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        return true if (entities.select {|e| e.match? entity}).length > 0
      end

      def entities
        entities=[]
        task_results.each {|x| x.entities.each {|e| entities << e } }
      entities
      end

      # just calculate it vs storing another property
      def timestamp_start
        return task_results.first.timestamp_start if task_results.first
      nil
      end

      # just calculate it vs storing another property
      def timestamp_end
        return task_results.last.timestamp_end if complete
      nil
      end

      ###
      ### Export!
      ###
      def export_hash
        {
          "id" => id,
          "name" => URI.escape(name),
          "depth" => depth,
          "complete" => complete,
          "strategy" => strategy,
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "filter_strings" => filter_strings.join(","),
          "project" => project.name,
          "base_entity" => base_entity.export_hash,
          #"task_results" => task_results.map{|t| t.export_hash },
          "entities" => entities.map {|e| e.export_hash },
          "options" => options,
          "log" => log
        }
      end

      def export_json
        export_hash.to_json
      end

      def export_csv
        output_string = ""
        self.entities.sort_by{|e| e.to_s }.each{ |x| output_string << x.export_csv << "\n" }
      output_string
      end

      def handle
        handled = []
        self.handlers.each do |handler_type|
          handler = Intrigue::HandlerFactory.create_by_type(handler_type)
          handled << handler.process(self)
        end
      handled
      end

      def handle(handler_type)
        handler = Intrigue::HandlerFactory.create_by_type(handler_type)
        handler.process(self)
      end

    end
  end
end
