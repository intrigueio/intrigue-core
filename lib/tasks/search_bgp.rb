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
      :allowed_types => ["IpAddress","NetBlock","Organization", "String", "UniqueKeyword"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => ["AutonomousSystem","NetBlock","Organization"]
    }
  end

  def run
    super
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    if entity_type == "Organization" || entity_type == "String" || entity_type == "UniqueKeyword"
      search_by_org_name entity_name
    elsif entity_type == "IpAddress"

      # lookup the netblock
      out = whois entity_name
      out.each do |hash|
        if hash["start_address"]
          netblock_name = hash["start_address"]
          # lookup the BGP data by netblock
          _log_good "Searching Netblocks for: #{netblock_name}"
          search_netblocks netblock_name
        else
          _log_error "Didn't get a start address, printing full text"
          _log hash["whois_full_text"]
        end
      end

    elsif entity_type == "NetBlock"
      search_netblocks entity_name
    else
      _log_error "Unsupported entity type"
    end

  end

  def search_netblocks(entity_name)

    begin
      lookup_name = entity_name.split("/").first
      json_resp = JSON.parse http_get_body "https://app.intrigue.io/api/bgp/netblock/search/#{lookup_name}"

      json_resp.each do |r|

        org_string = r["org"].split(",").first
        _create_entity "Organization", {"name" => "#{org_string}", "full" => org_string}

        as_number_string = "AS#{r["asnumber"]}"
        _create_entity "AutonomousSystem", {"name" => as_number_string, "netblocks" => r["netblocks"] }

      end
    rescue JSON::ParserError => e
      _log_error "Error parsing: #{e}"
    end
  end

  def search_by_org_name(entity_name)
    begin
      json_resp = JSON.parse http_get_body "https://intrigue.io/api/bgp/org/search/#{URI.escape(entity_name)}"

      json_resp.each do |r|

        org_string = r["org"].split(",").first
        _create_entity "Organization", {"name" => "#{org_string}", "full" => org_string}

        as_number_string = "AS#{r["asnumber"]}"
        _create_entity "AutonomousSystem", {"name" => as_number_string, "netblocks" => r["netblocks"] }

        # this key doesn't always exist
        if r["netblocks"]
          r["netblocks"].each do |nb|
            _create_entity "NetBlock", {
              "name" => "#{nb}",
              "organization_name" => org_string,
              "as_number" => as_number_string,
              "scoped" => true
            }
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
