module Intrigue
module Workers
class GenerateMetaGraphWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(id)

    # Get the right object
    project = Intrigue::Model::Project.where(:id => id).first

    begin
      puts "Starting META graph generation for #{project.name}!"

      # Notify that it's in progress
      project.graph_generation_in_progress = true
      project.save

      # Generate the graph
      project.graph_json = generate_meta_graph(project)
      project.graph_generated_at = DateTime.now
      project.graph_generation_in_progress = false
      project.save

      puts "Done with META graph generation for #{project.name}!"
      puts "Length: #{project.graph_json.length}"
    ensure
      project.graph_generation_in_progress = false
      project.save
    end
  end

  def generate_meta_graph(project)

    # generate the nodes
    nodes = []
    edges = []
    edge_count = 0

#      params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
#      params[:entity_types] == "" ? @entity_types = nil : @entity_types = params[:entity_types]

    selected_entities = Intrigue::Model::Entity.scope_by_project(project.name).where(:hidden => false)

    ## Filter if we have a type
#      selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

    ## We have some very rudimentary searching capabilities here
#      selected_entities = selected_entities.where(Sequel.|(
#        Sequel.ilike(:name, "%#{@search_string}%"),
#        Sequel.ilike(:details_raw, "%#{@search_string}%"))) if @search_string

    # Do the meta-analysis
    @entity_groups = []
    selected_entities.each do |se|
      alias_map = [se] | se.aliases.map{|a| a }

      merged = false
      @entity_groups.each do |e|
        e.each do |x|
          if alias_map.include? x
            e = e | alias_map
            merged = true
          end
        end
      end

      @entity_groups << alias_map unless merged
    end

    @entity_groups.each do |entity_group|
      #next unless t.base_entity.type_string == "IpAddress"

      nodes <<  { :id => entity_group.first.id, :label => "#{entity_group}", :type => "Meta"}

      # Figure out the edges
      entity_group.each do |e|
        e.task_results.each do |t|

          source_group = @entity_groups.select{ |x| x.include? t.base_entity }.first

          target_group = @entity_groups.select{ |x| x.include? e }.first

          next unless source_group && target_group

          edges << {"id" => edge_count += 1, "source" => source_group.first.id, "target" => target_group.first.id }

        end
      end

    end

    # dump the json
    { "nodes" => nodes, "edges" => edges }.to_json
  end

end
end
end
