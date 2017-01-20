module Intrigue
  module Model
    class ScanResult < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      #set_allowed_columns :project_id, :logger_id, :base_entity_id, :name, :depth, :handlers, :strategy, :filter_strings

      many_to_one :logger
      many_to_one :project
      one_to_many :task_results
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      #include Intrigue::Model::Capabilities::ExportGraph
      include Intrigue::Model::Capabilities::HandleResult

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def validate
        super
        #validates_unique([:name, :project_id, :depth])
      end

      def start(queue)
        task_results.first.start(queue)

        # kick off a background task that waits until all tasks are completed
        handle_result if handlers.length > 0
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
          "name" =>  URI.escape(name),
          "depth" => depth,
          "complete" => complete,
          "strategy" => strategy,
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "filter_strings" => filter_strings,
          "base_entity" => self.base_entity.export_hash,
          "task_results" => self.task_results.map{|t| t.export_hash },
          "entities" => self.entities.map {|e| e.export_hash },
          "options" => options,
          "log" => log
        }
      end

      def export_json
        export_hash.to_json
      end

      def export_csv
        output_string = ""
        self.entities.each{ |x| output_string << x.export_csv << "\n" }
      output_string
      end

      def export_graph_csv
        output_string = ""
        # dump the entity name, all chilren entity names, and
        # remove both spaces and commas
        self.entities.each do |x|
          output_string << x.name.gsub(/[\,,\s]/,"") << ", " << "#{x.children.map{ |y| y.name.gsub(/[\,,\s]/,"") }.join(", ")}\n"
        end
      output_string
      end

    end
  end
end
