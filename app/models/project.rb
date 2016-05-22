module Intrigue
  module Model
    class Project
      include DataMapper::Resource

      property :id,       Serial, :key => true
      property :name,     String

      validates_uniqueness_of :name

      def entity_count
        Intrigue::Model::Entity.all(:project_id => @id).count
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
