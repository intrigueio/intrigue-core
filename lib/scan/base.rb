module Intrigue
module Scanner
  class Base
    include Sidekiq::Worker
    include Intrigue::Task::Helper

    attr_accessor :id

    def perform(id)
      @scan_result = Intrigue::Model::ScanResult.find(id)
      @scan_log = @scan_result.log

      # Kick off the scan
      @scan_log.log  "Starting scan #{@scan_result.name} of type #{self.class} with id #{@scan_result.id} on entity #{@scan_result.entity.type}##{@scan_result.entity.attributes["name"]} to depth #{@scan_result.depth}"
      _recurse(@scan_result.entity,@scan_result.depth)
      @scan_log.good "Complete!"
    end

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])
      @scan_log.log "Starting #{task_name} with options #{options} on #{entity.type}##{entity.attributes["name"]} at depth #{depth}"

      # Check existing task results and see if we aleady have this answer
      task_result = Object.new
      @scan_result.task_results.each do |t|
        if (t.task_name == task_name && t.entity.type == entity.type && t.entity.attributes["name"] == entity.attributes["name"])
           # We have a match
           @scan_log.log "Found a duplicate task_result for #{task_name} on #{entity.type}##{entity.attributes["name"]}. Cloning results!"
           task_result = t.clone
           next # break out of the block
        end
      end

      # Check to see if we found an already-run task_result. If not, run it.
      unless task_result.kind_of? Intrigue::Model::TaskResult
        # Create an ID
        task_id = SecureRandom.uuid

        @scan_log.log "Kicking off task!"
        # Start the task run
        start_task_run(task_id, task_name, entity, options)

        # Wait for the task to complete
        task_result = Intrigue::Model::TaskResult.find task_id
        until task_result.complete
          #puts "Sleeping waiting for #{task_result}"
          sleep 1
          task_result = Intrigue::Model::TaskResult.find task_id
        end

        @scan_log.log "Got task result"
      end

=begin
    # XXX - Store the results for later lookup, avoid duplication (which should save a ton of time)
    key = "#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"
    if $results[key]
      puts "ALREADY FOUND: #{$results[key]["entity"]["attributes"]["name"]}"

      ###
      ### TODO find entity and link
      ###
      #old_entity = Neography::Node.find ....
      #node.outgoing(:child) << old_entity

      return
    else
      $results["#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"] = result
    end
=end

      @scan_log.log "Parsing entities..."
      # Display results in the log
      task_result.entities.each do |entity|
        #@scan_log.log "Entity: #{entity.type}##{entity.attributes["name"]}"
        @scan_result.add_entity(entity)
      end

      # add it to the scan result
      #@scan_log.log "Adding task to results..."
      @scan_result.add_task_result(task_result)

      # Then iterate on each entity
      task_result.entities.each do |entity|
        @scan_log.log "Iterating on #{entity.type}##{entity.attributes["name"]}"

        # create a new node
        #this = Neography::Node.create(
        #  type: y["type"],
        #  name: y["attributes"]["name"],
        #  task_log: y["task_log"] )
        # store it on the current entity
        #node.outgoing(:child) << this

        # recurse!
        _recurse(entity, depth-1)
      end
    end

  end
end
end
