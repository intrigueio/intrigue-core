module Intrigue
  module Model
    class Project
      include DataMapper::Resource

      property :id,       Serial, :key => true
      property :name,     String, :length => 400, :index => true

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
        # Add the base entity
        self.entities.each do |e|
          nodes << { :id => e.id, :label => "#{e.name}" }
        end

        # calculate child edges
        edges = []
        edge_count = 1
        self.task_results.each do |t|
          t.entities.each do |e|
            edges << {"id" => edge_count, "source" => t.base_entity.id, "target" => e.id}
            # Hack, since it seems like our entities list doesn't contain everything.
            #nodes << {:id => e.id, :label => "#{e.type}: #{e.name}"}
            #nodes.uniq! {|x| x[:id]}
            edge_count += 1
          end
        end

        # dump the json
        { "nodes" => nodes, "edges" => edges }.to_json
      end

    end
  end
end
