module Intrigue
module Scanner
  class Base
    include Sidekiq::Worker
    sidekiq_options :queue => "#{$intrigue_config.config["intrigue_queues"]["scan_queue"]}", :backtrace => true

    include Intrigue::Task::Helper

    def perform(id)
      @scan_result = Intrigue::Model::ScanResult.get(id)
      return unless @scan_result

      # list of entities we'll want filtered based on name
      @filter_list = @scan_result.filter_strings.split(",")

      # Kick off the scan
      @scan_result.timestamp_start = DateTime.now
      @scan_result.logger.log "Starting scan #{@scan_result.name} of type " +
          "#{self.class} with id #{@scan_result.id} on entity " + "#{@scan_result.base_entity.type_string}##{@scan_result.base_entity.name} " +
          "to depth #{@scan_result.depth}"
      _recurse(@scan_result.base_entity, @scan_result.depth)

      # Mark the task complete
      @scan_result.complete = true
      @scan_result.logger.log_good "Run complete. Ship it!"

      @scan_result.handlers.each do |handler_type|
        @scan_result.logger.log "Processing #{handler_type} handler."
        begin
          handler = HandlerFactory.create_by_type(handler_type)
          response = handler.process(@scan_result)
        rescue Exception => e
          @scan_result.logger.log_error "Unable to process handler #{handler_type}: #{e}"
          @scan_result.logger.log_error "Got response: #{response}"
        end
      end

      cleanup
      @scan_result.save
    end

    def cleanup
      @scan_result.logger.save
    end

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])

      @scan_result.logger.log "RECURSING (#{depth}) on #{entity}... #{task_name} #{options}"
      @scan_result.logger.log "Starting #{task_name} with options #{options} " +
        "on #{entity.type_string}##{entity.name} at depth #{depth}"

      # Make sure we can check for these later
      already_completed = false
      task_result = nil
      previous_task_result_id = nil

      # Check existing task results and see if we aleady have this answer
      @scan_result.logger.log "Checking previous results..."
      @scan_result.task_results.each do |t|
        #@scan_result.logger.log "t: #{t.inspect}"
        #@scan_result.logger.log "t.base_entity: #{t.base_entity.inspect}"
        #@scan_result.logger.log "entity: #{entity.inspect}"
        if (t.task_name == task_name &&
            t.base_entity.type_string == entity.type_string &&
            t.base_entity.name == entity.name)
          # We have a match
          @scan_result.logger.log "Already have results from a task with name #{task_name} and entity #{entity.type_string}:#{entity.name}"
          already_completed = true
          previous_task_result_id = t.id
        end
      end

      # Check to see if we found an already-run task_result. If not, run it.
      unless already_completed

        @scan_result.logger.log "No previous results, kicking off a task!"
        task_id = start_task_run(task_name, entity, options)

        # Wait for the task to complete
        @scan_result.logger.log "Task started, waiting for results"
        task_result = Intrigue::Model::TaskResult.get task_id

        # Set the appropriate project, based on the scan result
        # TODO - is there a better way to manage this?
        task_result.project = @scan_result.project
        task_result.save

        # Add the task_result to the scan_result
        @scan_result.logger.log "Adding new task result..."
        @scan_result.add_task_result(task_result)

        until task_result.complete
          # TODO - add explicit timeout here
          sleep 5
          task_result = Intrigue::Model::TaskResult.get task_id
        end
        @scan_result.logger.log "Task complete!"

      else
        @scan_result.logger.log "We already have results. Grabbing existing task results: #{task_name} on #{entity.type_string}##{entity.name}."
        # task result has already been cloned above, move on
        task_result = Intrigue::Model::TaskResult.get previous_task_result_id
      end

      # Iterate on each discovered entity
      task_result.entities.map do |entity|
        @scan_result.add_entity entity # Add these in right away
      end

      # Iterate on each discovered entity
      task_result.entities.map do |entity|
        @scan_result.logger.log "Iterating on #{entity.type_string}##{entity.name}"
        _recurse(entity, depth-1)
      end

    end

  end
end
end
