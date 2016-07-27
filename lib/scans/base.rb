module Intrigue
module Scanner
  class Base
    include Sidekiq::Worker
    sidekiq_options :queue => "#{Intrigue::Config::GlobalConfig.new.config["intrigue_queues"]["scan_queue"]}", :backtrace => true

    include Intrigue::Task::Helper

    def self.inherited(base)
      ScanFactory.register(base)
    end

    def perform(id)

      @scan_result = Intrigue::Model::ScanResult.get(id)
      return false unless @scan_result

      # list of entities we'll want filtered based on name
      @filter_list = @scan_result.filter_strings.split(",")

      # Kick off the scan
      @scan_result.timestamp_start = DateTime.now
      @scan_result.logger.log_good "Starting scan #{@scan_result.name} of type " +
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
      @scan_result.logger.log "Starting a task #{task_name} on #{entity.name}."

      # Make sure we can check for these later
      task_already_completed = false
      task_result = nil
      previous_task_result_id = nil

      @scan_result.logger.log "Checking pre-existing tasks: " +
      "#{Intrigue::Model::TaskResult.scope_by_project(@scan_result.project.name).all.count}"

      # We should check outside of the scan results
      Intrigue::Model::TaskResult.scope_by_project(@scan_result.project.name).all(
        :task_name => task_name).each do |t|

        # Verify we have it
        if ( t.base_entity.type_string == entity.type_string &&
             t.base_entity.name == entity.name &&
             t.complete )

          # Mark it as complete
          task_already_completed = true
          previous_task_result_id = t.id
        end

      end

      # Check to see if we found an already-run task_result.
      if task_already_completed

        @scan_result.logger.log "We already have results. Grabbing existing task results: #{task_name} on #{entity.type_string} #{entity.name}."
        # task result has already been cloned above, move on
        task_result = Intrigue::Model::TaskResult.get previous_task_result_id

      else # If not, run it.

        @scan_result.logger.log_good "Starting #{task_name} with options #{options} " +
          "on #{entity.type_string}##{entity.name} at depth #{depth}"

        # Start a new task
        task_id = start_task_run(@scan_result.project.id, @scan_result.id, task_name, entity, options)
        task_result = Intrigue::Model::TaskResult.get task_id

        # Add the task_result to the scan_result
        @scan_result.add_task_result(task_result)

        # Wait for the task to complete
        until task_result.complete
          # TODO - add explicit timeout here
          sleep 5
          task_result = Intrigue::Model::TaskResult.get task_id
        end

        @scan_result.logger.log "Task complete!"
      end

      # Iterate on each discovered entity
      task_result.entities.map do |entity|
        @scan_result.add_entity entity # Add these in right away
      end

      # Iterate on each discovered entity
      task_result.entities.map do |entity|
        @scan_result.logger.log "Iterating on discovered entity: #{entity.type_string}##{entity.name}"
        _recurse(entity, depth-1)
      end

    end

  end
end
end
