module Intrigue
module Task
class SearchHaveIBeenPwned < BaseTask

  def self.metadata
    {
      :name => "search_have_i_been_pwned",
      :pretty_name => "Search Have I Been Pwned (HIBP)",
      :authors => ["jcran"],
      :description => "Uses the Github API to search for the existence of a string in repository and user names",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [
        {"type" => "EmailAddress", "details" => {"name" => "nobody@nowhere.com"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    email_address = _get_entity_name

    results = _get_hibp_response_by_email(email_address)

    # TODO deal with pagination here
    if results.count > 0
      _log_good "Found #{results.count} items!" 
    else
      _log "No results found."
    end

    results.each do |result|

      if result["IsSensitive"]

        # create an issue for each found result
        _create_issue({
          name: "Leaked account: #{email_address} on #{result["Domain"]} at #{result["BreachDate"]}",
          type: "leaked_account_details",
          severity: 4,
          status: "confirmed",
          description: "Details for a leaked account were found in Have I Been Pwned." + 
                        "User: #{email_address} Domain: #{result["Domain"]}.\n" + 
                        "The details were leaked on #{result["BreachDate"]}.\n" +
                        "About this Breach:\n#{result["Description"]}",
          details: result
        })

      end

      # TODO - create a web account? 
    end


  end

  def _get_hibp_response_by_email(email_address)

    _log "Searching HIBP for #{email_address}"

    begin
      url = "https://haveibeenpwned.com/api/v2/breachedaccount/#{email_address}"

      response = http_request :get, url, nil, { "User-Agent" => "intrigue-core #{IntrigueApp.version}"}
      json = JSON.parse(response.body)   

    rescue JSON::ParserError
      _log_error "Error retrieving results"
    end

  json || []
  end

end
end
end
