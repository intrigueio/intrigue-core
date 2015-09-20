module Intrigue
module Scanner
  class Base

    include Sidekiq::Worker
    include Intrigue::Task::Helper

    attr_accessor :id

    def perform(id)
      @scan_result = Intrigue::Model::ScanResult.find(id)

      return unless @scan_result

      # log
      @scan_log = @scan_result.log

      # list of entities we'll want filtered based on name

      @filter_list = @scan_result.filter_strings.split(",")

      # Kick off the scan
      @scan_log.log  "Starting scan #{@scan_result.name} of type #{self.class} with id #{@scan_result.id} on entity #{@scan_result.entity.type}##{@scan_result.entity.attributes["name"]} to depth #{@scan_result.depth}"
      _recurse(@scan_result.entity,@scan_result.depth)

      # Mark the task complete
      @scan_result.complete = true
      @scan_result.save
      @scan_log.good "Complete!"
    end

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])
      @scan_log.log "Starting #{task_name} with options #{options} on #{entity.type}##{entity.attributes["name"]} at depth #{depth}"

      # Make sure we can check for these later
      already_completed = false
      task_result = nil
      previous_task_result_id = nil

      # Check existing task results and see if we aleady have this answer
      @scan_result.task_results.each do |t|
        if (t.task_name == task_name && t.entity.type == entity.type && t.entity.attributes["name"] == entity.attributes["name"])
          # We have a match
          already_completed = true
          previous_task_result_id = t.id
        end
      end

      # Check to see if we found an already-run task_result. If not, run it.
      unless already_completed
        # Create an ID
        task_id = SecureRandom.uuid

        # Start the task run
        @scan_log.log "Kicking off task!"

        start_task_run(task_id, task_name, entity, options)

        # Wait for the task to complete
        task_result = Intrigue::Model::TaskResult.find task_id
        until task_result.complete
          #puts "Sleeping waiting for #{task_result}"
          sleep 1
          task_result = Intrigue::Model::TaskResult.find task_id
        end

        # Parse out entities and add'm
        @scan_log.log "Parsing entities..."
        task_result.entities.each do |new_entity|
            unless @scan_result.has_entity? new_entity
              @scan_result.add_entity(new_entity)
            end
        end

        # add the task_result
        @scan_log.log "Adding new task result..."
        @scan_result.add_task_result(task_result) unless already_completed

      else
        @scan_log.log "Found a duplicate task_result for #{task_name} on #{entity.type}##{entity.attributes["name"]}. Cloning results!"
        # task result has already been cloned above, move on
        task_result = Intrigue::Model::TaskResult.find previous_task_result_id
      end

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
