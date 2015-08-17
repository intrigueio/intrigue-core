module Intrigue
module Scanner
  class Base
    include Sidekiq::Worker
    include Intrigue::Task::Helper

    attr_accessor :id

    def perform(id)
      puts "PERFORM CALLED ON SCAN #{id}"

      @scan_result = Intrigue::Model::ScanResult.find(id)

      puts "Got scan result #{@scan_result}"
      @scan_log = @scan_result.log

      # Kick off the scan
      @scan_log.log  "Starting scan #{@scan_result.name} of type #{self.class} with id #{@scan_result.id} on entity #{@scan_result.entity} to depth #{@scan_result.depth}"
      _recurse(@scan_result.entity,@scan_result.depth)
      @scan_log.good "Complete!"
    end

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])

      # Create an ID
      task_id = SecureRandom.uuid
      start_task_run(task_id, task_name, entity, options)

=begin


      # XXX - Create the task
      @scan_log.log "Calling #{task_name} on #{entity}"
      task = TaskFactory.create_by_name(task_name)

      ###
      ### Okay, so listen. the webhooks idea was great and all, but this is too much. We don't have a way
      ### to get the current uri to send this guy to. So we basically have to hardcode, or try to pass it
      ### through the database per-client. just yuck. So get rid of the webhooks in favor of redis-backing
      ### everything and make the webhooks available afterward.
      ###

      jid = task.class.perform_async task_id, entity, options, ["webhook"], "http://127.0.0.1:7777/v1/task_runs/#{task_id}"
=end
      ### Wait for the task to complete
      #complete = false
      task_result = Intrigue::Model::TaskResult.find task_id
      until task_result.complete
        #puts "Sleeping waiting for #{task_result}"
        sleep 1
        task_result = Intrigue::Model::TaskResult.find task_id
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

      # add it to the task result
      @scan_result.add_task_result(task_result)

      # Display results in the log
      task_result.entities.each do |entity|
        @scan_log.log "Entity: #{entity.type} #{entity.attributes["name"]}"
        @scan_result.add_entity(entity)
      end

      # Then iterate on them
      task_result.entities.each do |entity|

        # create a new node
        #this = Neography::Node.create(
        #  type: y["type"],
        #  name: y["attributes"]["name"],
        #  task_log: y["task_log"] )
        # store it on the current entity
        #node.outgoing(:child) << this

        # recurse!
        @scan_log.log "Iterating on #{entity}"
        _recurse(entity, depth-1)
      end
    end

  end
end
end
