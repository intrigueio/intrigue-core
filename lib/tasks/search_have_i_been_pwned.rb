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
      :allowed_options => [
        {:name => "search_breaches", :regex => "boolean", :default => true },
        {:name => "search_pastes", :regex => "boolean", :default => true },
        {:name => "only_sensitive", :regex => "boolean", :default => false },
        {:name => "create_issues", :regex => "boolean", :default => true }
      ],
      :created_types => []
    }
  end

  

  ## Default method, subclasses must override this
  def run
    super

    email_address = _get_entity_name

    @api_key = _get_task_config("hibp_api_key")
    unless @api_key 
      _log_error "unable to proceed, no API key for HIBP provided"
      return
    end

    _search_pastes_and_create_issues(email_address)
    _search_breaches_and_create_issues(email_address)

  end


  def _search_pastes_and_create_issues(email_address)
    _log "Searching HIBP Pastes for #{email_address}"
    results = _get_hibp_response("pasteaccount/#{email_address}")

    # TODO deal with pagination here
    if results.count > 0
      _log_good "Found #{results.count} paste entries!" 
    else
      _log "No results found."
    end

    results.each do |result|
      _log "Result: #{result}"
      # create an issue for each found result
      _create_issue({
         name: "Email account found in Paste: #{email_address} in #{result["Source"]} on #{result["Date"]}",
         type: "email_found_in_paste",
         severity: 4,
         status: "confirmed",
         description: "Email account found in paste: #{email_address} in " + 
                     "#{result["Source"]} on #{result["Date"]} with #{result["EmailCount"] - 1} others.",
         details: result
      }) if _get_option("create_issues")
    end

  end

  def _search_breaches_and_create_issues(email_address)

    _log "Searching HIBP Breaches for #{email_address}"
    results = _get_hibp_response("breachedaccount/#{email_address}?truncateResponse=false")

    # TODO deal with pagination here
    if results.count > 0
      _log_good "Found #{results.count} breach entries!" 
    else
      _log "No results found."
    end

    results.each do |result|
      next if _get_option("only_sensitive") && !result["IsSensitive"]      
      # create an issue for each found result
      _create_issue({
        name: "Leaked account: #{email_address} on #{result["Domain"]} at #{result["BreachDate"]}",
        type: "email_found_in_breach",
        severity: 4,
        status: "confirmed",
        description: "Email account was found in a breach of : #{result["Name"]}\n" +  
                      "User: #{email_address} Domain: #{result["Domain"]}.\n" + 
                      "The details were leaked on #{result["BreachDate"]}.\n" +
                      "About this Breach:\n#{result["Description"]}",
        details: result
      }) if _get_option("create_issues")
    end

  end

  def _get_hibp_response(endpoint)

    begin
      url = "https://haveibeenpwned.com/api/v3/#{endpoint}"

      response = http_request(:get, url, nil, { 
        "hibp-api-key" => @api_key,
        "User-Agent" => "intrigue-core #{IntrigueApp.version}",
        "Accept" => "application/json"
      })

      json = JSON.parse(response.body)   

    rescue JSON::ParserError
      _log_error "Error retrieving results"
    end

  json || []
  end

end
end
end
