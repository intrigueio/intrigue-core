
module Intrigue
module Task
class CollectionProcessor < BaseTask

  include Intrigue::System

  HOSTNAME=`hostname`.strip

  def self.metadata
    {
      :name => "control/collection_processor",
      :pretty_name => "Control - Collection Processor",
      :authors => ["jcran"],
      :description => "This processor takes collection instructions from a configured queue and reports its status.",
      :references => [],
      :type => "control",
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => { "name" => "NA" }}
      ],
      :allowed_options => [],
      :created_types => [],
      :queue => "control"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    config = _get_task_config "control/collection_processor"

    @sqs = Aws::SQS::Client.new({
      region: 'us-east-1',
      access_key_id: config["aws_access_key"],
      secret_access_key: config["aws_secret_access_key"]
    })

    @control_queue_uri = config["control_queue_uri"]
    @status_queue_uri = config["status_queue_uri"]
    sleep_interval = config["sleep"] || 10
    max_seconds = config["max_seconds"] || 36000

    handler = config["handler"]

    # connect to the configured amazon queue & Grab one
    _set_status :available, nil
    instruction_data = nil
    iteration = 0
    while true

      # loop until we have something
      while !instruction_data

        _log "Attempting to get an instruction from the queue!"
        instruction_data = _get_queued_instruction # try again

        # kick it off if we got one, and break out of this loop
        if instruction_data
          _log "[+] Executing #{instruction_data["id"]} for #{sleep_interval} seconds! (expire in: ~#{max_seconds - (iteration * sleep_interval) }s)"
          _set_status :start, "#{instruction_data["id"]}"
          _execute_instruction(instruction_data)
        else
          _log "Nothing to do, waiting!"
          sleep sleep_interval
        end

      end

      # hold tight
      sleep sleep_interval

      # determine how we're doing
      task_count_left = _tasks_left
      seconds_elapsed = iteration * sleep_interval
      done = (iteration > 10 && task_count_left == 0 ) || (seconds_elapsed  > max_seconds)

      _log "Seconds elapsed: #{seconds_elapsed}" if iteration % 10 == 0
      _log "Tasks left: #{task_count_left}" if iteration % 10 == 0

      if done
        _log_good "Done with #{instruction_data["id"]} after #{seconds_elapsed}s"
        _set_status :end, {
          "id" => "#{instruction_data["id"]}",
          "elapsed" => "#{seconds_elapsed}",
          "entities" => "#{Intrigue::Model::Project.first(:name => instruction_data["id"]).entities.count}"
        }

        _log_good "#{instruction_data["id"]}"
        _run_handlers instruction_data
        _set_status :sent, "#{instruction_data["id"]}"

        instruction_data = nil
        iteration = -1

      end

      iteration +=1
    end

  end


  # method pulls a queue
  def _get_queued_instruction

    begin

      # pull from the priority queue first
      queue_uri = "#{@control_queue_uri}_priority_100"
      response = @sqs.receive_message(queue_url: queue_uri, max_number_of_messages: 1)


      # otherwise go to the normal queue
      unless response.messages.count > 0
        queue_uri = @control_queue_uri
        response = @sqs.receive_message(queue_url: queue_uri, max_number_of_messages: 1)
      end

      control_message = {}
      response.messages.each do |m|

        if (m && m.body)

          @sqs.delete_message({
            queue_url: queue_uri,
            receipt_handle: m.receipt_handle
          })

          # return the first one
          message = JSON.parse(m.body)
          _log "Got instruction for #{message["id"]}"
          _log "#{message}"

          return message

        else
          _log_error "No instructions received!!!"
          return nil
        end
      end
    rescue JSON::ParserError => e
      _log_error "Can't parse response"
    rescue Aws::SQS::Errors::NonExistentQueue
      _log_error "A queue named '#{queue_name}' does not exist."
    end

  false
  end

  def _set_status(s, details=nil)
    status = {
      :hostname => HOSTNAME,
      :timestamp => DateTime.now,
      :status => s,
      :details => details
    }
    _log "Setting status to: #{status}"

    begin
      # Create a message with three custom attributes: Title, Author, and WeeksOn.
      send_message_result = @sqs.send_message({
        queue_url: @status_queue_uri,
        message_body: "#{status.to_json}"
      })
    rescue Aws::SQS::Errors::NonExistentQueue
      _log "A queue named '#{queue_name}' does not exist."
    end

  end

  def _execute_instruction data
    Dir.chdir $intrigue_basedir do
      bootstrap_system data
    end
  end

  def _run_handlers instruction_data
    # run core-cli here?
    Dir.chdir $intrigue_basedir do

      id = instruction_data["id"]
      # TODO - this currently only works for the first project.
      handlers = instruction_data["projects"].first["handlers"]

      project = Intrigue::Model::Project.first(:name => id)
      handlers.each do |h|
        if project
          project.handle(h, "#{id}/")
        else
          _log_error "unable to call #{h} on project #{id}"
        end
      end

    end
  end

  def _tasks_left
    ps = Sidekiq::ProcessSet.new
    count = -1 # remove our control thread right off the bat
    ps.each do |process|
      count += process['busy']     # => 3
    end
    count += Sidekiq::Stats.new.enqueued
  end

end
end
end
