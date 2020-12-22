module Intrigue
module Workers
class GenerateGraphWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "graph", :backtrace => true

  def perform(id)

    # Get the right object
    project = Intrigue::Core::Model::Project.where(:id => id).first

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

      # add the base entity first (provided it hasn't been deleted)
      b = t.base_entity

      unless b.deleted?
        x = { 
          :id => b.id, 
          :label => "#{b.name}", 
          :type => b.type_string }

          # set the color
          x[:color] = "#ffffa0" if b.issues.count > 0
          x[:color] = "#ff0000" if b.issues.count > 0 && b.issues.find{|i| i.severity < 3 }
          x[:color] = "#808080" unless b.scoped

        nodes << x
      end
    
      # then for each of the entities, generate the node and edges. skip if deleted.
      t.entities.each do |e|
        next if e.deleted?

        x = { 
          :id => e.id, 
          :label => "#{e.name}", 
          :type => e.type_string } 

        # set the color
        x[:color] = "#ffffa0" if e.issues.count > 0
        x[:color] = "#ff0000" if e.issues.count > 0 && e.issues.find{|i| i.severity < 3 }
        x[:color] = "#808080" unless e.scoped

        nodes << x 

        unless t.base_entity.deleted?
          edges << { 
            "id" => edge_count += 1, 
            "source" => b.id, 
            "target" => e.id
          }
        end

      end
      
    end

  # dump the json
  { "nodes" => nodes.uniq{|x| x[:id] }, "edges" => edges }
  end




end
end
end
