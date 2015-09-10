module Intrigue
class PhoneNumberCarrierLookup < BaseTask

  include Task::Web

  def metadata
    {
      :name => "phone_number_carrier_lookup",
      :pretty_name => "Phone Number Carrier Lookup",
      :authors => ["jcran"],
      :description => "This task uses the CarrierLookup API to determine the provider of a phone number",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [ {"type" => "PhoneNumber", "attributes" => {"name" => "202-456-1414"}} ],
      :allowed_options => [ ],
      :created_types => [] # only edits the phone number
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    phone_number = _get_entity_attribute("name").gsub(".","").gsub(" ","").gsub("-","")
    api_key = _get_global_config "carrierlookup_api_key"

    balance_uri = "http://www.carrierlookup.com/index.php/api/balance?key=#{api_key}"
    lookup_uri = "http://www.carrierlookup.com/index.php/api/lookup?key=#{api_key}&number=#{phone_number}"

    begin
      #@task_log.log "Current balance: #{http_get_body balance_uri}"
      response = http_get_body lookup_uri
      attributes = JSON.parse response if response

      if attributes["Response"]["error"]
        @task_log.error "Error querying API #{attributes["Response"]["error"]}"
        return
      end

      @task_log.log "You have #{attributes["Response"]["creditBalance"]} credits remaining."

      # edit the phone number entity
      @entity.attributes["carrier_type"] = attributes["Response"]["carrier_type"]
      @entity.attributes["carrier"] = attributes["Response"]["carrier"]
      @task_log.log "Updating PhoneNumber entity: #{@entity.inspect}"
      @task_log.log "Carrier Type: #{@entity.attributes["carrier_type"]}"
      @task_log.log "Carrier: #{@entity.attributes["carrier"]}"

      @entity.save

      # add an info entity_ids
      #{}_create_entity "Info", attributes.merge({"name" => "Carrier Lookup for #{phone_number}: #{attributes}"})

    rescue JSON::ParserError
      @task_log.error "Unable to retrieve provider info"
    end

  end

end
end
