module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results

      include Intrigue::Model::Capabilities::ExportGraph

      def validate
        super
        validates_unique(:name)
      end

      def entity_count
        Intrigue::Model::Entity.where(:project_id => id).count
      end

      def entities
        Intrigue::Model::Entity.where(:project_id => id)
      end

      def export_hash
        { :id => id,
          :name => name,
          :entities => entities.map {|e| e.export_json },
          :task_results => task_results.map {|t| t.export_json }
        }
      end

    end
  end
end
