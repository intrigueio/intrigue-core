module Intrigue
  module Model
    class Project
      include DataMapper::Resource

      property :id,       Serial, :key => true
      property :name,     String, :length => 400, :index => true
      property :graph_json, Text, :length => 999999
      property :graph_generated_at, DateTime
      property :graph_generation_in_progress, Boolean, :default => false

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

      def export_graph_json
        # generate the nodes
        nodes = []
        edges = []
        edge_count = 1
        self.task_results.each do |t|
          # add the base entity first
          nodes << { :id => t.base_entity.id, :label => "#{t.base_entity.name}", :type => t.base_entity.type_string }
          # then for each of the entities, generate the node and edges
          t.entities.each do |e|
            nodes << { :id => e.id, :label => "#{e.name}", :type => e.type_string }
            edges << {"id" => edge_count, "source" => t.base_entity.id, "target" => e.id}
            edge_count += 1
          end
        end

        # dump the json
        { "nodes" => nodes.uniq!, "edges" => edges }.to_json
      end

    end
  end
end
