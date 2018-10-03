module Intrigue
module Task
class SecurityTrailsSubdomains < BaseTask

  def self.metadata
    {
      :name => "security_trails_subdomains",
      :pretty_name => "Security Trails Subdomains",
      :authors => ["jcran"],
      :description => "This task hits the Security Trails API and finds subdomains.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Make sure the key is set
    api_key = _get_task_config "security_trails_api_key"
    entity_name = _get_entity_name
    uri = "https://api.securitytrails.com/v1/domain/#{entity_name}/subdomains"

    begin
      # get the data. seriously could this be any easier?
      resp = http_get_body uri, nil, {"APIKEY" => api_key}
      json = JSON.parse(resp)

      _log "Got #{json["subdomains"].count} subdomains!"

      json["subdomains"].each do |x|
        _create_entity "DnsRecord", "name" => "#{x}.#{entity_name}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get a properly formatted response"
    end


  end # end run()

end
end
end
