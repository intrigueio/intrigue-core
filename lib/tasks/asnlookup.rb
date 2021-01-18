module Intrigue
  module Task
  class AsnLookup < BaseTask
  
    def self.metadata
      {
        :name => "asn_lookup",
        :pretty_name => "ASN Lookup",
        :authors => ["m-q-t", "yassineaboukir"],
        :description => "Uses http://asnlookup.com API to return netblocks belonging to Organization.",
        :references => ["http://asnlookup.com"],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Organization", "String", "UniqueKeyword"],
        :example_entities => [
          {"type" => "String", "details" => {"name" => "Salesforce"}}
        ],
        :allowed_options => [],
        :created_types => ["Netblock"]
      }
    end
  
    def run
      super

      # get our enitty 
      org = _get_entity_name

      # get the netblocks 
      r = org_to_netblocks(org)

      return unless r

      r.each do |nb|
        begin
        _create_entity "NetBlock", {
          "name" => "#{nb}",
          "organization_name" => org,
        }
      rescue => e
        _log_error "error: #{e}"
      end 
      end
    end
  
    def org_to_netblocks(org)
      begin
        resp = http_get_body "http://asnlookup.com/api/lookup?org=#{URI.escape(org)}"

        json_resp = JSON.parse resp
      rescue JSON::ParserError => e
        _log_error "Error parsing: #{e}"
      end
    end
  
  end
  end
  end
  