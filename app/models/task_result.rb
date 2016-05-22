module Intrigue
  module Model
    class TaskResult
      include DataMapper::Resource

      belongs_to :logger, 'Intrigue::Model::Logger'
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }
      belongs_to :base_entity, 'Intrigue::Model::Entity'

      has n, :entities, :through => Resource, :constraint => :destroy
      has n, :scan_results, :through => Resource, :constraint => :destroy

      property :id, Serial, :key => true
      property :name, String
      property :task_name, String
      property :timestamp_start, DateTime
      property :timestamp_end, DateTime
      property :options, Object, :default => [] #StringArray
      property :complete, Boolean, :default => false

      def self.scope_by_project(name)
        all(:project => Intrigue::Model::Project.first(:name => name))
      end


      def add_entity(entity)
        return false if has_entity? entity

        entity.task_results << self
        entity.save

        self.entities << entity

        save
      true
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        self.entities.each {|e| return true if e.match?(entity) }
      false
      end

      ###
      ### Export!
      ###

      def export_csv
        output_string = ""
        self.entities.each{ |x| output_string << x.export_csv << "\n" }
      output_string
      end

      def export_tsv
        export_string = ""
        self.entities.map{ |x| export_string << x.export_tsv + "\n" }
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
          "log" => self.logger.full_log
        }
      end

      def export_json
        export_hash.to_json
      end

    end
  end
end
