module Intrigue
module Workers
class GenerateGraphWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "graph", :backtrace => true

  def perform(id)

    # Get the right object
    project = Intrigue::Model::Project.where(:id => id).first

    begin
      puts "Starting graph generation for #{project.name}!"

      # Notify that it's in progress
      project.graph_generation_in_progress = true
      project.save

      # Generate the graph
      project.graph_json = generate_graph(project).to_json
      project.graph_generated_at = DateTime.now

      puts "Done with graph generation for #{project.name}!"
      puts "Length: #{project.graph_json.length}"
    ensure
      project.graph_generation_in_progress = false
      project.save
    end

  end

  def generate_graph(project)
    # generate the nodes
    nodes = []
    edges = []
    edge_count = 0

    project.task_results.each do |t|

      #next unless t.base_entity.type_string == "IpAddress"

      # add the base entity first (provided it hasn't been deleted)
      x = { :id => t.base_entity.id, :label => "#{t.base_entity.name}", :type => t.base_entity.type_string}
      nodes << x unless t.base_entity.deleted?

      # then for each of the entities, generate the node and edges. skip if deleted.
      t.entities.each do |e|

        #next unless e.type_string == "IpAddress"

        x = { :id => e.id, :label => "#{e.name}", :type => e.type_string } #unless e.secondary
        #x[:color] = "lightgrey" if e.type_string == "Uri"

        nodes << x unless e.deleted?

        unless t.base_entity.deleted? || e.deleted?
          edges << {"id" => edge_count += 1, "source" => t.base_entity.id, "target" => e.id}
        end

      end
    end

    # dump the json
    { "nodes" => nodes.uniq!, "edges" => edges }
  end



end
end
end
