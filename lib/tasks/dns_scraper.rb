module Intrigue
class DnsScraper < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "dns_scraper",
      :pretty_name => "DNS Scraper",
      :authors => ["jcran"],
      :description => "This task scrapes known APIs for subdomains and creates new DnsRecord entities.",
      :references => ["https://github.com/aboul3la/Sublist3r/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [ {"type" => "DnsRecord", "details" => {"name" => "intrigue"}} ],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Check Sublist3r API & create domains from returned JSON
    search_domain = _get_entity_name
    search_uri = "https://api.sublist3r.com/search.php?domain=#{search_domain}"
    begin
      domains = JSON.parse(http_get_body(search_uri))
    rescue JSON::ParserError
      _log_error "Unable to get parsable response from #{search_uri}"
    end
    domains.each{|d| _create_entity("DnsRecord", {"name" => "#{d}"})}



  end

end
end
