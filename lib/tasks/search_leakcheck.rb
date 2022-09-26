module Intrigue
module Task
class SearchLeakCheck < BaseTask

  def self.metadata
  {
    :name => "search_leakcheck",
    :pretty_name => "Search LeakCheck",
    :authors => ["ZwCreatePhoton"],
    :description => "This task uses the LeakCheck API to search for leaked accounts.",
    :references => ["https://leakcheck.net/api_s"],
    :type => "discovery",
    :passive => true,
    :allowed_types => ["EmailAddress", "Domain", "PhoneNumber", "String"],
    :example_entities => [
      {"type" => "EmailAddress", "details" => {"name" => "nobody@nowhere.com"}},
      {"type" => "Domain", "details" => {"name" => "intrigue.io"}},
      {"type" => "PhoneNumber", "details" => {"name" => "214-456-7890"}},
      {"type" => "String", "details" => {"name" => "username, password, keyword, password_hash, email_hash"}}
    ],
    :allowed_options => [
      {:name => "request_type", :regex => "alpha_numeric", :default => "auto" },
      {:name => "extended_api", :regex => "boolean", :default => true },
      {:name => "create_issues", :regex => "boolean", :default => true }
    ],
    :created_types => ["EmailAddress", "PhoneNumber"]
  }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    api_key =_get_task_config("leakcheck_api_key")

    unless api_key
      _log_error "unable to proceed, no API key for LeakCheck provided"
      return
    end

    extended_api = _get_option("extended_api")

    request_type = _get_option("request_type")

    if entity_type == "EmailAddress"
      query = entity_name
      request_type = "email"
    elsif entity_type == "Domain"
      unless extended_api
        _log_error "The Domain entity type is only supported when using the Extended API. An Enterprise plan is required."
      end
      query = entity_name
      request_type = "domain_email"
    elsif entity_type == "PhoneNumber"
      unless extended_api
        _log_error "The PhoneNumber entity type is only supported when using the Extended API."
      end
      query = entity_name.tr('(-) ', '')
      request_type = "phone"
    elsif entity_type == "String"  # username, password, password_hash, email_hash, keyword for related leaks
      query = entity_name
    else
      _log_error "Unsupported entity type"
      return
    end

    search_and_create_issues api_key, query, request_type, extended_api
  end

  def search_and_create_issues api_key, query, request_type, extended_api
    _log "Querying the LeakCheck #{extended_api ? "Extended" : "Public"} API"
    json = search_leakcheck api_key, query, request_type, extended_api

    if json
      if json["success"]
        _log_good "Found #{json["found"]} entries!"
      elsif json["error"].eql? "Not found"
        _log "No results found."
        return
      else
        _log_error "API Error: #{json["error"]}"
        return
      end
    else
      _log "No results found."
      return
    end

    results = json[extended_api ? "result" : "sources"]

    results&.each do |result|
      account = extended_api ? result["line"].split(':', 2).first : query
      linked_entity = nil

      # create entities
      if extended_api && account != query
        if %w[email mass hash pass_email phash domain_email].include? request_type
          email = account
          linked_entity = _create_entity "EmailAddress" , {"name" => email}
        elsif %w[pass_phone phone].include? request_type
          phone = account
          linked_entity = _create_entity "PhoneNumber" , {"name" => phone}
        end
      end

      # create issues
      password_leaked = extended_api ? result["email_only"] == 0 : false
      sources = extended_api ? result["sources"] : [result]
      sources.each do |source|
        source_name = extended_api ? source : source["name"]
        description = "The account \"#{account}\" was found in publicly leaked data from the #{source_name} data breach."
        description += "The account's plain text password was included in the leak." if password_leaked
        instance_specifics = {
          proof: result,
          name: "Account Found In LeakCheck Public Breach Database (#{account})",
          description: description,
          severity: password_leaked ? 3 : 2,
          source: source_name,
          details: result,
          references: [
            { type: "description", uri: "https://leakcheck.net/"}
          ]
        }
        if _get_option("create_issues")
          if linked_entity.nil?
            _create_linked_issue("leaked_account", instance_specifics)
          else
            _create_linked_issue("leaked_account", instance_specifics, linked_entity)
          end
        end
      end
    end
  end

  # Search LeakCheck using the query "check" of type "type" using API key "key"
  def search_leakcheck key, check, type, extended_api

    try_counter = 0
    max_tries = 2

    begin
      endpoint = extended_api ? "api" : "api/public"
      url = "https://leakcheck.net/#{endpoint}?key=#{key}&check=#{check}"
      url += "&type=#{type}" if extended_api

      response = nil
      json = nil

      until json || (try_counter == max_tries)
        try_counter += 1
        sleep_time = rand(2..10)

        response = http_request(:get, url, nil, {
          "User-Agent" => "intrigue-core",
          "Accept" => "application/json"
        })

        unless response&.body_utf8
          puts "No results!"
          return
        end

        # Okay we got something
        begin
          json = JSON.parse(response.body_utf8)

          # in case it's blank
          unless json
            puts "Unable to get response, sleeping #{sleep_time}s"
            sleep sleep_time
            next
          end

          if json.kind_of? Hash
            # okay
            status_code = response.code.to_i

            if status_code && status_code == 429
              puts "Rate limit hit, sleeping #{sleep_time}s"
              json = nil # reset
              sleep sleep_time
            elsif status_code && status_code != 200
              puts "Lookup did not return a 200 (returned #{status_code}), sleeping #{sleep_time}s"
              json = nil # reset
              sleep sleep_time
            else # status_code == 200
              unless json["success"]
                unless json["error"].eql? "Not found"
                  puts "API Error: #{json["error"]}"
                end
              end
            end
          end

          # in case we can't parse it
        rescue JSON::ParserError => e
          puts "Error retrieving JSON results: #{response}, failing"
          break
        end

      end

      unless response && json
        puts "Error! Failed to get results from the LeakCheck API"
      end

    end

    json
  end

end
end
end
