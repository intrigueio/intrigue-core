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
    sleep_interval = 10 #config["sleep"]
    handler = config["handler"]

    # connect to the configured amazon queue
    _log "[+] Marking us as starting in the #{@status_queue_uri} queue!"
    _set_status "starting"

    # connect to the configured amazon queue & Grab one
    _log "[+] Connecting to the #{@control_queue_uri} queue!"
    instruction_data = _get_queued_instruction

    if !instruction_data
      _log "nothing to do!"
      return
    end

    # process
    _log "[+] Marking us as processing in the #{@status_queue_uri} queue!"
    _log "[+] Processing!"
    _set_status "processing #{instruction_data["id"]}"
    _execute_instruction instruction_data

    iteration = 0
    while true

      # hold right
      _log "[+] Holding tight for #{sleep_interval} seconds! (#{iteration})"
      sleep sleep_interval

      # TODO - check sidekiq busy queue (also have a fallback if it's "stuck")
      done = (Sidekiq::Stats.new.enqueued == 0 || iteration > 100
      )
      _log "Locally queued tasks: #{Sidekiq::Stats.new.enqueued}"

      if done

        _set_status "finished #{instruction_data["id"]}"
        # connect to the configured amazon queue & Grab one
        #_log "[+] Connecting to the #{control_queue_uri} queue!"
        #instruction = _get_queued_instruction

        # go into shutdown if that's a configured option
        #_set_status "shutdown"
        #_shutdown
        return true

      end

      # run the configured handlers on a regular basis
      if iteration % 10 == 0
        _log "[+] Running handler #{handler}: #{iteration % 10}."
        _set_status "Handling #{instruction_data["id"]}"
        _run_handlers instruction_data
      end

      iteration +=1
    end

  end


  # method pulls a queue
  def _get_queued_instruction
    _log "[+] Kicking off collection!"

    begin
      # pull from the queue
      response = @sqs.receive_message(queue_url: @control_queue_uri, max_number_of_messages: 1)


      control_message = {}
      response.messages.each do |m|
      _log "Got message: #{m}"

        if (m && m.body)

          _log "Removing: #{m}"
          @sqs.delete_message({
            queue_url: @control_queue_uri,
            receipt_handle: m.receipt_handle
          })

          # return the first one
          return JSON.parse(m.body)

        else
          _log_error "NO INSTRUCTIONS!!!"
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
      _log "[.] DEBUG: Executing... #{data}"
      bootstrap_system data
    end
  end

  def _run_handlers instruction_data
    _log "[.] DEBUG: _run_handlers called on #{instruction_data["id"]}"
    # run core-cli here?
    Dir.chdir $intrigue_basedir do

      # TODO parse json and get client id
      id = instruction_data["id"]
      handlers = instruction_data["handlers"]

      handlers.each do |h|
        Intrigue::Model::Project.first(:name => id).handle(h, id)
      end

      #_log "[.] DEBUG: rbenv sudo bundle exec /home/ubuntu/core/core-cli.rb local_handle_all_projects data.intrigue.io #{id}"
      #`rbenv sudo bundle exec /home/ubuntu/core/core-cli.rb local_handle_all_projects data.intrigue.io #{id}`
    end
  end

  def _shutdown
    `sudo -b shutdown -H 0`
  end


end
end
end
