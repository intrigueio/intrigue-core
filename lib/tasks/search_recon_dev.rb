module Intrigue
module Task
class SearchReconDev < BaseTask

  def self.metadata
    {
      :name => "search_recon_dev",
      :pretty_name => "Search Recon.dev",
      :authors => ["jcran", "nahamsec"],
      :description => "Search @nahamsec's Recon.dev API for DnsRecords and Uris. " + 
        "This API was released at DEFCON Safe Mode (2020)",
      :references => ["https://twitter.com/NahamSec/status/1291804914943836161"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"} }
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name 
    recon_dev_key = _get_task_config "recon_dev_api_key"

    begin
      
      # grab the response from the api
      response = http_get_body "https://api.recon.dev/search?domain=#{domain}&key=#{recon_dev_key}"
      json = JSON.parse(response)
      
      # check if it exists, since we'll get a 'null' if it doesnt
      if json 
        _log "Parsing #{json.count} results" 

        if json == ["message", "Forbidden"]
          _log_error "Invalid Key?"
          return
        end

        # grab each one, so we can clean them up individually
        subdomains = []
        urls = []
        json.each do |j|
          next unless j
          subdomains << "#{j["rawDomain"]}".gsub("*.","")
          urls << "#{j["domain"]}".gsub(".*","")
        end    

        # create subdomains
        subdomains.uniq.each do |s|
          create_dns_entity_from_string s
        end

        # create uris
        urls.uniq.each do |url|
          _create_entity "Uri", "name" => "#{url}"
        end

      else 
        _log "No results found"
      end

    rescue JSON::ParserError => e
      _log "Error parsing json"
    end

  end
end
end
end
