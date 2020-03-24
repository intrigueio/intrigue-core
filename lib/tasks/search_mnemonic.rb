module Intrigue
module Task
class SearchMnemonic < BaseTask

  def self.metadata
    {
      :name => "search_mnemonic",
      :pretty_name => "Search Mnemonic",
      :authors => ["Anas Ben Salah"],
      :description => "This task offers passive DNS data by querying passive DNS data collected in malware lab.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain", "IpAddress"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "limit", :regex => "integer", :default => 0 }
      ],
      :created_types => ["DnsRecord", "IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string
    limit = _get_option("limit")


    response = http_get_body("https://api.mnemonic.no/pdns/v3/#{entity_name}?limit=#{limit}")
    result = JSON.parse(response)


    #check if the resultset exceeds server resource constraints
    if result["responseCode"] == 421
      _log_error("the requested resultset exceeds server resource constraints (100 000 values currently)")
      #return
    end

    # Check if data different to null
    if result["data"] == nil
      _log_error("object.not.found")
      return
    end

    # Get all the related IPs to the domain name
    if entity_type =="Domain"
      result["data"].each do |e|
        _create_entity("IpAddress", {"name" => e["answer"], "mnemonic_details" => e})
      end
    # Get all the domain names related to the IP
    elsif entity_type =="IpAddress"
      result["data"].each do |e|
        _create_entity("DnsRecord", {"name" => e["query"], "mnemonic_details" => e })
      end
    # log error if Unsupported entity type
    else
      _log_error "Unsupported entity type"
    end #end if

  end #end run

end
end
end
