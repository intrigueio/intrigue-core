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
        {:name => "search_pastes", :regex => "boolean", :default => false },
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

    _search_pastes_and_create_issues(email_address) if _get_option("search_pastes")
    _search_breaches_and_create_issues(email_address) if _get_option("search_breaches")
  end

  def _search_pastes_and_create_issues(email_address)
    _log "Searching HIBP Pastes for #{email_address}"
    results = _get_hibp_response("pasteaccount/#{email_address}")

    # TODO deal with pagination here
    if results
      _log_good "Found #{results.count} paste entries!"
    else
      _log "No results found."
      return
    end

    results.each do |result|

      _create_linked_issue("leaked_account",{
         name: "Email Account Found In HIBP (Public Breach Data)",
         severity: 3,
         description: result["Description"],
         source: result["Name"],
         details: result
      }) if _get_option("create_issues")
    end

  end

  def _search_breaches_and_create_issues(email_address)

    _log "Searching HIBP Breaches for #{email_address}"
    results = _get_hibp_response("breachedaccount/#{email_address}?truncateResponse=false")

    # TODO deal with pagination here
    if results
      _log_good "Found #{results.count} breach entries!"
    else
      _log "No results found."
      return
    end

    results.each do |result|
      next if _get_option("only_sensitive") && !result["IsSensitive"]
      # create an issue for each found result
      _create_linked_issue("leaked_account",{
        name: "Email Account Found In HIBP (Public Breach Data)",
        severity: 3,
        description: result["Description"],
        source: result["Name"],
        details: result
       }) if _get_option("create_issues")
    end
  end

  def _get_hibp_response(endpoint)

    try_counter = 0
    max_tries = 2

    begin
      url = "https://haveibeenpwned.com/api/v3/#{endpoint}"

      response = nil
      json = nil

      until json || (try_counter == max_tries)
        try_counter += 1
        sleep_time = rand(20)

        response = http_request(:get, url, nil, {
          "hibp-api-key" => @api_key,
          "User-Agent" => "intrigue-core 0.7",
          "Accept" => "application/json"
        })

        unless response && response.body
          _log_error "No results!"
          return
        end

        # Okay we got something
        begin
          json = JSON.parse(response.body)

          # in case it's blank
          unless json
            _log_error "Unable to get response, sleeping #{sleep_time}s"
            sleep sleep_time
            next
          end

          if json.kind_of? Hash
            # okay
            status_code = json["statuscode"]

            if status_code && status_code.to_i == 429
              _log_error "Rate limit hit, sleeping #{sleep_time}s"
              json = nil # reset
              sleep sleep_time
            elsif status_code && status_code.to_i == 503
              _log_error "Service unavailable, sleeping #{sleep_time}s"
              json = nil # reset
              sleep sleep_time
            elsif status_code && status_code.to_i == 401
              _log_error "Invalid key?"
              return
            end
          end

        # in case we can't parse it
        rescue JSON::ParserError => e
          _log_error "Error retrieving JSON results: #{response}, failing"
          break
        end

      end

      unless response && json
        _log "Error! Failed to get results from the HIBP api"
      end

    end

  json
  end

end
end
end


