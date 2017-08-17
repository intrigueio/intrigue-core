module Intrigue
module Task
class SearchPhishtank < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_phishtank",
      :pretty_name => "Search Phishtank",
      :authors => ["jcran"],
      :description => "Uses the Phishtank API to search for a uri",
      :references => [],
      :type => "discovery",
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
    api_key = _get_global_config("phishtank_api_key")

    # Search
    search_uri = "http://checkurl.phishtank.com/checkurl/"
    params = {:format => "json", :app_key => api_key, :url => URI.escape(entity_name) }
    response = _get_json_response(search_uri, params)

    if response["results"]["in_database"]
      _create_entity "Info", :name => "Phishtank URI: #{entity_name}", :raw => response
    else
      _log "No results in database: #{response.inspect}"
    end
  end

  def _get_json_response(uri,data)
    begin
      response = http_post(uri,data)
      parsed_response = JSON.parse(response)
    rescue JSON::ParserError => e
      _log "Error retrieving results: #{e}"
    end
  parsed_response
  end

end
end
end
