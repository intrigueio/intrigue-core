module Intrigue
module Task
class SearchBgp < BaseTask

  def self.metadata
    {
      :name => "search_bgp",
      :pretty_name => "Search BGP",
      :authors => ["jcran"],
      :description => "Use BGP Looking Glass Data to find Networks for a given Organization or AS number.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Organization", "String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => ["NetBlock","AutonomousSystem"]
    }
  end

  def run
    super
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    puts "#{entity_type}: #{entity_name}"

    begin
      json_resp = JSON.parse http_get_body "https://resource.intrigue.io/org/search/#{URI.escape(entity_name)}"
      _log "Got response: #{json_resp}"

      json_resp.each do |r|
        _create_entity "Organization", {"name" => "#{r["org"].split(",").first}"}
        _create_entity "AutonomousSystem", {"name" => "AS#{r["asnumber"]}"}

        # this key doesn't always exist
        if r["netblocks"]
          r["netblocks"].each do |nb|
            _create_entity "NetBlock", {"name" => "#{nb}"}
          end
        end

      end
    rescue JSON::ParserError => e
      _log_error "Error parsing: #{e}"
    end
  end

end
end
end
