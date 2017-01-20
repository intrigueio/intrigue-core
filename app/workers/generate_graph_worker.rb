module Intrigue
module Workers
class GenerateGraphWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(id)

    # Get the right object
    result = Intrigue::Model::Project.where(:id => id).first

    begin
      puts "Starting graph generation for #{result.name}!"

      # Notify that it's in progress
      result.graph_generation_in_progress = true
      result.save

      # Generate the graph
      result.graph_json = result.export_graph_json
      result.graph_generated_at = DateTime.now
      result.graph_generation_in_progress = false
      result.save

      puts "Done with graph generation for #{result.name}!"
      puts "Length: #{result.graph_json.length}"
    rescue StandardError => e
      puts "Hit an exception while generating graph for #{result}"
      puts "Error: #{e}"
    ensure
      result.graph_generation_in_progress = false
      result.save
    end

  end

end
end
end
