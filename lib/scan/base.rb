module Intrigue
module Scanner
  class Base
    include Sidekiq::Worker

    private

    def _start_task_and_recurse(task_name,entity,depth,options=[])
      # Create an ID
      task_id = SecureRandom.uuid

      # XXX - Create the task
      @log.log "Calling #{task_name} on #{entity}"
      task = TaskFactory.create_by_name(task_name)

      ###
      ### Okay, so listen. the webhooks idea was great and all, but this is too much. We don't have a way
      ### to get the current uri to send this guy to. So we basically have to hardcode, or try to pass it
      ### through the database per-client. just yuck. So get rid of the webhooks in favor of redis-backing
      ### everything and make the webhooks available afterward.
      ###

      jid = task.class.perform_async task_id, entity, options, ["webhook"], "http://127.0.0.1:7777/v1/task_runs/#{task_id}" # "#{$intrigue_server_uri}/task_runs/#{task_id}"

      ### Wait for the task to complete
      complete = false
      until complete
        sleep 1
        response = $intrigue_redis.get("result:#{task_id}")
        if response
          complete = true
        end
      end

      # Parse the result
      result = JSON.parse response

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
      # Iterate on the results
      result['entities'].each do |result|
        @log.log "New Entity: #{result["type"]} #{result["attributes"]["name"]}"

        # create a new node
        #this = Neography::Node.create(
        #  type: y["type"],
        #  name: y["attributes"]["name"],
        #  task_log: y["task_log"] )
        # store it on the current entity
        #node.outgoing(:child) << this

        # recurse!
        _recurse(result, depth-1)
      end

    end

    # List of prohibited entities - returns true or false
    def _is_prohibited entity

      if entity["type"] == "NetBlock"
        cidr = entity["attributes"]["name"].split("/").last.to_i
        return true unless cidr >= 22
      else
        return true if (
          entity["attributes"]["name"] =~ /google/             ||
          entity["attributes"]["name"] =~ /g.co/               ||
          entity["attributes"]["name"] =~ /goo.gl/             ||
          entity["attributes"]["name"] =~ /android/            ||
          entity["attributes"]["name"] =~ /urchin/             ||
          entity["attributes"]["name"] =~ /youtube/            ||
          entity["attributes"]["name"] =~ /schema.org/         ||
          entity["attributes"]["description"] =~ /schema.org/  ||
          entity["attributes"]["name"] =~ /microsoft.com/      ||
          #entity["attributes"]["name"] =~ /yahoo.com/         ||
          entity["attributes"]["name"] =~ /facebook.com/       ||
          entity["attributes"]["name"] =~ /cloudfront.net/     ||
          entity["attributes"]["name"] =~ /twitter.com/        ||
          entity["attributes"]["name"] =~ /w3.org/             ||
          entity["attributes"]["name"] =~ /akamai/             ||
          entity["attributes"]["name"] =~ /akamaitechnologies/ ||
          entity["attributes"]["name"] =~ /amazonaws/          ||
          entity["attributes"]["name"] == "feeds2.feedburner.com"
        )
      end
    false
    end
  end
end
end
