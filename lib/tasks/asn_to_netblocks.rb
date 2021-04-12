module Intrigue
  module Task
  class AsnToNetblocks < BaseTask
  
    def self.metadata
      {
        :name => "asn_to_netblocks",
        :pretty_name => "ASN to Netblocks",
        :authors => ["jcran", "Punisher876"],
        :description => "Use BGP Data to find Networks for a given ASN.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["AutonomousSystem"],
        :example_entities => [
          {"type" => "AutonomousSystem", "details" => {"name" => "AS17676"}}
        ],
        :allowed_options => [],
        :created_types => ["Netblock"]
      }
    end
  
    def run
      super

      # get our enitty 
      asn = _get_entity_name

      # get the netblocks 
      r = asn_to_netblocks(asn.gsub("as",""))

      # create the organization entity
      if r["org"]
        org_string = r["org"].split(",").first
        _create_entity "Organization", {"name" => "#{org_string}", "full" => org_string}
      end

      # make sure we have some, or return
      return unless r["netblocks"]

      # create a netblock entity for each
      r["netblocks"].each do |nb|
        _create_entity "NetBlock", {
          "name" => "#{nb}", 
          "organization_name" => org_string, 
          "as_number" => asn
        }
      end
    
    end
  
    def asn_to_netblocks(entity_name)
      begin
        resp = http_get_body "https://api.intrigue.io/api/bgp/asn/#{URI.escape(entity_name)}"

        json_resp = JSON.parse resp
      rescue JSON::ParserError => e
        _log_error "Error parsing: #{e}"
      end
    end
  
  end
  end
  end
  