module Intrigue
  module Model
    class Project
      include DataMapper::Resource

      property :id,       Serial
      property :name,     String

      def self.current_project
        Intrigue::Model::Project.first
      end

      def entities
        Intrigue::Model::Entity.all(:project_id => @id)
      end

      def task_results
        Intrigue::Model::TaskResult.all(:project_id => @id)
      end

      def scan_results
        Intrigue::Model::ScanResult.all(:project_id => @id)
      end

    end
  end
end
