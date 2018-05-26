module Intrigue
module Task
class SecurityTrailsHistoricalWhois < BaseTask

  def self.metadata
    {
      :name => "security_trails_historical_whois",
      :pretty_name => "Security Trails Historical WHOIS",
      :authors => ["jcran"],
      :description => "This task hits the Security Trails API and grabs historical WHOIS data.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [{"type" => "EmailAddress", "details" => {"name" => "spam@intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Make sure the key is set
    api_key = _get_task_config "security_trails_api_key"
    entity_name = _get_entity_name
    uri = "https://api.securitytrails.com/v1/search/list"

    payload = {
      "filter": {
        "whois_email": "#{entity_name}"
      }
    }

    # get the data
    begin
      resp = http_request :post, uri, nil, {
        "APIKEY" => api_key,
        "Content-Type" => "application/json" }, payload.to_json

      if resp.code == "200"
        json = JSON.parse(resp.body)

        _log "Got #{json["records"].count} records!"

        json["records"].each do |x|
          _create_entity "DnsRecord", "name" => "#{x["hostname"]}", "security_trails_data" => x
        end
      else
        _log_error "Got invalid response: #{resp.code}\n#{resp.body}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get a properly formatted response"
    end

  end # end run()

end
end
end
