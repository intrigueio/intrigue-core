module Intrigue
  module Model
    class TaskResult < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      #set_allowed_columns :project_id, :logger_id, :base_entity_id, :name, :depth, :handlers, :strategy, :filter_strings

      many_to_many :entities
      many_to_one :scan_result
      many_to_one :logger
      many_to_one :project
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      #include Intrigue::Model::Capabilities::HandleResult

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def validate
        super
      end

      def start(queue)

        if queue == "task_autoscheduled"
          autoscheduled = true

          job_id = Sidekiq::Client.push({
            "class" => Intrigue::TaskFactory.create_by_name(task_name).class.to_s,
            "queue" => "task_autoscheduled",
            "retry" => true,
            "args" => [id]
          })

          save

        else # start it in the task queues
          task = Intrigue::TaskFactory.create_by_name(task_name)
          job_id = task.class.perform_async self.id
          save
        end

      end

      def log
        logger.full_log
      end

      def strategy
        return scan_result.strategy if scan_result
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

      ### Export!
      def export_csv
        output_string = ""
        entities.each{ |x| output_string << x.export_csv << "\n" }
      output_string
      end

      def export_tsv
        export_string = ""
        entities.map{ |x| export_string << x.export_tsv + "\n" }
      export_string
      end

      def export_hash
        {
          "id" => id,
          "job_id" => job_id,
          "name" =>  URI.escape(name),
          "task_name" => URI.escape(task_name),
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "options" => options,
          "complete" => complete,
          "base_entity" => base_entity.export_hash,
          "entities" => entities.map{ |e| {:id => e.id, :type => e.type, :name => e.name, :details => e.details } },
          "log" => log
        }
      end

      def export_json
        export_hash.to_json
      end

    end
  end
end
