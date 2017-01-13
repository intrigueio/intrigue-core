module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results

      def validate
        super
        #validates_uniqueness_of :name
      end

      def entity_count
        Intrigue::Model::Entity.where(:project_id => id).count
      end

      def entities
        Intrigue::Model::Entity.where(:project_id => id)
      end

      def task_results
        Intrigue::Model::TaskResult.where(:project_id => id)
      end

      def scan_results
        Intrigue::Model::ScanResult.where(:project_id => id)
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
            #next unless e.type_string == "WebServer"
            nodes << { :id => e.id, :label => "#{e.name}", :type => e.type_string } #unless e.secondary
            edges << {"id" => edge_count, "source" => t.base_entity.id, "target" => e.id} #unless e.secondary
            edge_count += 1
          end
        end

        # dump the json
        { "nodes" => nodes.uniq!, "edges" => edges }.to_json
      end

    end
  end
end
