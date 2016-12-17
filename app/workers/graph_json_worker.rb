module Intrigue
module Workers
class GraphJsonWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(project_id)

    # Get the project
    project = Intrigue::Model::Project.first(:id =>project_id)

    begin
      puts "Starting graph generation for #{project.name}!"



      # Notify that it's in progress
      project.graph_generation_in_progress = true
      project.save

      # Generate the graph
      project.graph_json = project.export_graph_json
      project.graph_generated_at = DateTime.now
      project.graph_generation_in_progress = false
      project.save

      puts "Done with graph generation for #{project.name}!"
      puts "Length: #{project.graph_json.length}"
    rescue StandardException => e
      puts "Hit an exception while generating graph for project #{project}"
      puts "Error: #{e}"
    ensure
      project.graph_generation_in_progress = false
      project.save
    end
  end

end
end
end
