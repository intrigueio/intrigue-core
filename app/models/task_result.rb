module Intrigue
  module Model
    class TaskResult
      include DataMapper::Resource

      belongs_to :logger, 'Intrigue::Model::Logger'

      property :project_id, Integer, :index => true
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }

      property :base_entity_id, Integer, :index => true
      belongs_to :base_entity, 'Intrigue::Model::Entity'

      property :scan_result_id, Integer, :index => true
      belongs_to :scan_result, 'Intrigue::Model::ScanResult', :required => false

      has n, :entities, :through => Resource #, :constraint => :destroy

      property :id, Serial, :key => true
      property :name, String, :length => 200
      property :task_name, String, :length => 50
      property :timestamp_start, DateTime
      property :timestamp_end, DateTime
      property :options, Object, :default => []
      property :handlers, Object, :default => []
      property :complete, Boolean, :default => false
      property :entity_count, Integer, :default => 0
      property :depth, Integer, :default => 1

      def self.scope_by_project(project_name)
        all(:project => Intrigue::Model::Project.first(:name => project_name))
      end

      def log
        logger.full_log
      end

      def strategy
        return scan_result.strategy if scan_result
      nil
      end

      def add_entity(entity)
        return false if has_entity? entity

        begin
          attribute_set(:entity_count, @entity_count + 1)
          entity.task_results << self
          entity.save
          entities << entity
          save # TODO - this may be unnecessary
        rescue Exception => e
          false
        end

      true
      end

      # Start a task
      def start
        # TODO, keep track of the sidekiq id so we can control the task later
        task = Intrigue::TaskFactory.create_by_name(task_name)
        task.class.perform_async self.id, handlers
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        entities.each {|e| return true if e.match?(entity) }
      false
      end

      ###
      ### Export!
      ###
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
          "id" => @id,
          "name" =>  URI.escape(@name),
          "task_name" => URI.escape(@task_name),
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "options" => @options,
          "complete" => @complete,
          "base_entity" => self.base_entity.export_hash,
          "entities" => self.entities.map{ |x| x.export_hash },
          "log" => log
        }
      end

      def export_json
        export_hash.to_json
      end

    end
  end
end
