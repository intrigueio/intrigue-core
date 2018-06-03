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

        org_string = r["org"].split(",").first
        org_name = org_string.split("-").last.strip

        if org_name
          _create_entity "Organization", {"name" => "#{org_name}", "full" => org_string }
        else
          _create_entity "Organization", {"name" => "#{org_string}", "full" => org_string}
        end

        as_number_string = "AS#{r["asnumber"]}"
        _create_entity "AutonomousSystem", {"name" => as_number_string, "netblocks" => r["netblocks"] }

        # this key doesn't always exist
        if r["netblocks"]
          r["netblocks"].each do |nb|
            _create_entity "NetBlock", {"name" => "#{nb}", "organization" => org_string, "as_number" => as_number_string}
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
