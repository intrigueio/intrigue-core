module Intrigue
module Task
class SearchReconDev < BaseTask

  def self.metadata
    {
      :name => "search_recon_dev",
      :pretty_name => "Search Recon.dev",
      :authors => ["jcran", "nahamsec"],
      :description => "Search @nahamsec's Recon.dev API for subdomains and urls",
      :references => ["https://twitter.com/NahamSec/status/1291804914943836161"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"} }
      ],
      :allowed_options => [],
      :created_types => ["Organization"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name 

    begin
      response = _http_get_body "https://api.recon.dev/search?domain=#{domain}"
      json = JSON.parse(response)
    rescue JSON::ParserError => e
      _log "Error parsing json"
    end

    json.each do |j|
      _create_entity "DnsRecord", "name" => "#{j["rawDomain"]}"
      _create_entity "Uri", "name" => "#{j["domain"]}"
    end


  end
end
end
end
