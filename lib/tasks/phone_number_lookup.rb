module Intrigue
module Task
class PhoneNumberLookup < BaseTask

  include Task::Web

  def self.metadata
    {
      :name => "phone_number_lookup",
      :pretty_name => "Phone Number  Lookup",
      :authors => ["jcran"],
      :description => "This task uses the CarrierLookup API to determine the provider of a phone number",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["PhoneNumber"],
      :example_entities => [ {"type" => "PhoneNumber", "details" => {"name" => "202-456-1414"}} ],
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
    phone_number = _get_entity_name.gsub(".","").gsub(" ","").gsub("-","").gsub("(","").gsub(")","")

    # get the API key
    api_key = _get_task_config "carrierlookup_api_key"

    lookup_uri = "http://www.carrierlookup.com/index.php/api/lookup?key=#{api_key}&number=#{phone_number}"

    begin
      response = http_get_body lookup_uri
      details = JSON.parse response if response

      if details["Response"]["error"]
        _log_error "Error querying API #{details["Response"]["error"]}"
        return
      end

      _log "You have #{details["Response"]["creditBalance"]} credits remaining."
      _log "Carrier Type: #{details["Response"]["carrier_type"]}"
      _log "Carrier: #{details["Response"]["carrier"]}"

      # Edit the phone number entity
      _set_entity_detail("carrier_type", details["Response"]["carrier_type"])
      _set_entity_detail("carrier",details["Response"]["carrier"])

    rescue JSON::ParserError
      _log_error "Unable to retrieve provider info"
    end

  end

end
end
end
