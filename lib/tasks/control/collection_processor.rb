#require 'aws-sdk-sqs'

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

    Aws.config = {
      region: config["region"],
      access_key_id: config["aws_access_key"],
      secret_access_key: config["secret_access_key"]
    }

    @sqs = Aws::SQS::Client.new(region: 'us-east-1')

    @control_queue_uri = config["control_queue_uri"]
    @status_queue_uri = config["status_queue_uri"]
    sleep_interval = config["sleep"] || 30
    handler = config["handler"]

    # connect to the configured amazon queue & Grab one
    _set_status "starting"
    iteration = 0
    while true

      # loop until we have something
      while !instruction_data
        _log "Nothing to do, waiting!"
        sleep sleep_interval
        _log "Attempting to get an instruction from the queue!"
        instruction_data = _get_queued_instruction # try again

        # kick it off if we got one, and break out of this loop
        if instruction_data
          _log "[+] Executing #{instruction_data["id"]} for #{sleep_interval} seconds! (expire in: ~#{(200 - iteration) * sleep_interval / 60 }m)"
          _execute_instruction(instruction_data)
        end
      end

      # hold tight
      sleep sleep_interval

      # check sidekiq busy queue (also have a fallback if it's "stuck"...)
      # default is 1000 x 30 .. 3000 / 60 = 50mins
      done = (iteration > 10 && Sidekiq::Stats.new.enqueued == 0) || iteration > 200
      _log "Locally queued tasks: #{Sidekiq::Stats.new.enqueued}"

      if done
        _log_good "Done with #{instruction_data["id"]}"
        _set_status "completed #{instruction_data["id"]}"

        _log_good "#{instruction_data["id"]}"
        _run_handlers instruction_data
        _set_status "handled #{instruction_data["id"]}"

        instruction_data = nil
        iteration = 0

      end

      iteration +=1
    end

  end


  # method pulls a queue
  def _get_queued_instruction

    begin
      # pull from the queue
      response = @sqs.receive_message(queue_url: @control_queue_uri, max_number_of_messages: 1)

      control_message = {}
      response.messages.each do |m|

        if (m && m.body)

          @sqs.delete_message({
            queue_url: @control_queue_uri,
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

  def _set_status(s)
    status = "#{HOSTNAME}: #{s}"

    _log "Setting status to: #{status}"

    begin
      # Create a message with three custom attributes: Title, Author, and WeeksOn.
      send_message_result = @sqs.send_message({
        queue_url: @status_queue_uri,
        message_body: "#{status}"
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

  def _shutdown
    `sudo -b shutdown -H 0`
  end


end
end
end
