module Intrigue
module Task
class SecurityTrailsHistoricalDns < BaseTask

  def self.metadata
    {
      :name => "security_trails_historical_dns",
      :pretty_name => "Security Trails Historical DNS Lookup",
      :authors => ["jcran"],
      :description => "This task hits the Security Trails API and grabs the addresses associated with a given domain.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["IpAddress"]
    }
  end

  def run
    super

    # get our target
    domain_name = _get_entity_name

    # get the initial response, which will give us the number of pages
    response = _get_st_response domain_name, 1
    _log "got response: #{response}"

    # parse it out, create entities
    _parse_st_response(response)

    # hit the api again, only if we had more than one page
    if response["pages"] > 1
      (2..pages).each do |p|
        response _get_st_response domain_name, p
        _parse_st_response response
      end
    end

  end # end run()

  def _parse_st_response(resp)

    resp["records"].each do |r|
      r["values"].each do |v|
        _create_entity "IpAddress", {
          "name" => "#{v["ip"]}",
          "provider" => r["organizations"].join(", "),
          "security_trails_record" => v
        }
      end
    end
    
  end

  def _get_st_response(record,page)
    # get the data
    begin
      api_key = _get_task_config "security_trails_api_key"
      uri = "https://api.securitytrails.com/v1/history/#{record}/dns/a?page=#{page}"
      resp = http_get_body uri, nil, { "APIKEY" => api_key }
      json = JSON.parse(resp)
    rescue JSON::ParserError => e
      _log_error "Unable to get a properly formatted response"
    end

    json
  end

end
end
end
