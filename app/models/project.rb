module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results

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

          # add the base entity first (provided it hasn't been deleted)
          x = { :id => t.base_entity.id, :label => "#{t.base_entity.name}", :type => t.base_entity.type_string}
          #x[:color] = "lightgrey" if t.base_entity.secondary
          nodes << x unless t.base_entity.deleted?

          # then for each of the entities, generate the node and edges. skip if deleted.
          t.entities.each do |e|
            #next unless e.type_string == "WebServer"
            x = { :id => e.id, :label => "#{e.name}", :type => e.type_string } #unless e.secondary
            #x[:color] = "lightgrey" if e.secondary
            nodes << x unless e.deleted?

            unless t.base_entity.deleted? || e.deleted?
              edges << {"id" => edge_count, "source" => t.base_entity.id, "target" => e.id}
              edge_count += 1
            end
          end
        end

        # dump the json
        { "nodes" => nodes.uniq!, "edges" => edges }.to_json
      end

    end
  end
end
