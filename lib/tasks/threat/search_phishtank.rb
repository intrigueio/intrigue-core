module Intrigue
module Task
class SearchPhishtank < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "threat/search_phishtank",
      :pretty_name => "Threat Check - Search Phishtank",
      :authors => ["jcran"],
      :description => "Uses the Phishtank API to search for a uri",
      :references => [],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}],
      :allowed_options => [
      ],
      :created_types => ["Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    api_key = _get_task_config("phishtank_api_key")
    phishtank_username = _get_task_config("phishtank_username")

    # Search
    search_uri = "https://checkurl.phishtank.com/checkurl/"
    params = {:format => "json", :app_key => api_key, :url => URI.escape(entity_name) }
    headers = { 'user-agent': "phishtank/#{phishtank_username}" }

    # Make the request 
    response = _get_json_response(search_uri, params, headers)

    if response["results"]["in_database"]

      # create a malicious entity
      _create_entity "MaliciousUrl", {
        "name" => "#{entity_name}", 
        "extended_phishtank" => response
      }

    else
      _log "No results in database: #{response.inspect}"
    end
  end

  def _get_json_response(uri,data, headers)
    begin
      response = http_post(uri,data, headers)
      parsed_response = JSON.parse(response)
    rescue JSON::ParserError => e
      _log "Error retrieving results: #{e}"
    end
  parsed_response
  end

end
end
end
