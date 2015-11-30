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

    # Replace bad characters
    #
    # For future, consider:
    # http://stackoverflow.com/questions/20650681/ruby-gsub-multiple-characters-in-string
    phone_number = _get_entity_attribute("name").gsub(".","").gsub(" ","").gsub("-","").gsub("(","").gsub(")","")

    # get the API key
    api_key = _get_global_config "carrierlookup_api_key"

    lookup_uri = "http://www.carrierlookup.com/index.php/api/lookup?key=#{api_key}&number=#{phone_number}"

    begin
      response = http_get_body lookup_uri
      attributes = JSON.parse response if response

      if attributes["Response"]["error"]
        @task_result.logger.log_error "Error querying API #{attributes["Response"]["error"]}"
        return
      end

      @task_result.logger.log "You have #{attributes["Response"]["creditBalance"]} credits remaining."

      # Edit the phone number entity
      @entity.details["carrier_type"] = attributes["Response"]["carrier_type"]
      @entity.details["carrier"] = attributes["Response"]["carrier"]
      @entity.save

      @task_result.logger.log "Carrier Type: #{@entity.details["carrier_type"]}"
      @task_result.logger.log "Carrier: #{@entity.details["carrier"]}"

      # Add an info entity_ids
      #{}_create_entity "Info", attributes.merge({"name" => "Carrier Lookup for #{phone_number}: #{attributes}"})

    rescue JSON::ParserError
      @task_result.logger.log_error "Unable to retrieve provider info"
    end

  end

end
end
