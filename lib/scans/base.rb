module Intrigue
module Scanner
  class Base

    include Sidekiq::Worker
    include Intrigue::Task::Helper

    attr_accessor :id

    def perform(id)
      @scan_result = Intrigue::Model::ScanResult.get(id)
      return unless @scan_result

      # list of entities we'll want filtered based on name
      @filter_list = @scan_result.filter_strings.split(",")

      # Kick off the scan
      @scan_result.timestamp_start = DateTime.now
      @scan_result.log "Starting scan #{@scan_result.name} of type #{self.class} with id #{@scan_result.id} on entity #{@scan_result.entity.type_string}##{@scan_result.entity.name} to depth #{@scan_result.depth}"
      _recurse(@scan_result.entity, @scan_result.depth)

      # Mark the task complete
      @scan_result.log_good "Complete!"
      @scan_result.complete = true
      @scan_result.save
    end

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])
      @scan_result.log "Starting #{task_name} with options #{options} on #{entity.type_string}##{entity.name} at depth #{depth}"

      # Make sure we can check for these later
      already_completed = false
      task_result = nil
      previous_task_result_id = nil

      # Check existing task results and see if we aleady have this answer
      @scan_result.log "Checking previous results..."
      @scan_result.task_results.each do |t|
        @scan_result.log "t: #{t.inspect}"
        @scan_result.log "t.entity: #{t.entity.inspect}"
        @scan_result.log "entity: #{entity.inspect}"
        if (t.task_name == task_name &&
            t.entity.type_string == entity.type_string &&
            t.entity.name == entity.name)
          # We have a match
          @scan_result.log "Already have results from a task with name #{task_name} and entity #{entity.type_string}:#{entity.name}"
          already_completed = true
          previous_task_result_id = t.id
        end
      end

      # Check to see if we found an already-run task_result. If not, run it.
      unless already_completed

        @scan_result.log "No previous results, kicking off a task!"
        task_id = start_task_run(task_name, entity, options)

        # Wait for the task to complete
        @scan_result.log "Task started, waiting for results"
        task_result = Intrigue::Model::TaskResult.get task_id
        until task_result.complete # this will eventually time out and mark complete if the task fails. (900s)
          @scan_result.log "Sleeping, waiting for completion of task: #{task_id}"
          sleep 3
          task_result = Intrigue::Model::TaskResult.get task_id
        end
        @scan_result.log "Task complete!"

        # Parse out entities and add'm
        @scan_result.log "Parsing entities..."
        task_result.entities.each do |new_entity|
            unless @scan_result.has_entity? new_entity
              @scan_result.add_entity(new_entity)
            end
        end

        # add the task_result to the scan record
        @scan_result.log "Adding new task result..."
        @scan_result.add_task_result(task_result) unless already_completed

      else
        @scan_result.log "We already have results. Grabbing existing task results: #{task_name} on #{entity.type_string}##{entity.name}."
        # task result has already been cloned above, move on
        task_result = Intrigue::Model::TaskResult.get previous_task_result_id
      end

      # Then iterate on each entity
      task_result.entities.each do |entity|
        @scan_result.log "Iterating on #{entity.type_string}##{entity.name}"

        # This is currently unused, but where we can easily create a graph of results
        #this = Neography::Node.create(
        #  type: y["type"],
        #  name: y["attributes"]["name"],
        #  task_result: y["task_result"] )
        # store it on the current entity
        #node.outgoing(:child) << this

        # recurse!
        _recurse(entity, depth-1)
      end
    end

  end
end
end
