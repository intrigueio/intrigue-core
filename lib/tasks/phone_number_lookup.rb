module Intrigue
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
    phone_number = _get_entity_name.gsub(".","").gsub(" ","").gsub("-","").gsub("(","").gsub(")","")

    # get the API key
    api_key = _get_global_config "carrierlookup_api_key"

    lookup_uri = "http://www.carrierlookup.com/index.php/api/lookup?key=#{api_key}&number=#{phone_number}"

    begin
      response = http_get_body lookup_uri
      attributes = JSON.parse response if response

      if attributes["Response"]["error"]
        _log_error "Error querying API #{attributes["Response"]["error"]}"
        return
      end

      _log "You have #{attributes["Response"]["creditBalance"]} credits remaining."
      _log "Carrier Type: #{attributes["Response"]["carrier_type"]}"
      _log "Carrier: #{attributes["Response"]["carrier"]}"

      # Edit the phone number entity
      @entity.set_detail("carrier_type", attributes["Response"]["carrier_type"])
      @entity.set_detail("carrier",attributes["Response"]["carrier"])

    rescue JSON::ParserError
      _log_error "Unable to retrieve provider info"
    end

  end

end
end
