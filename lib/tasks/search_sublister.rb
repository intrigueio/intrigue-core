module Intrigue
class SearchSublister < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_sublister",
      :pretty_name => "Search Sublist3r",
      :authors => ["jcran"],
      :description => "This task hit Sublis3r's API for subdomains and creates new DnsRecord entities.",
      :references => ["https://github.com/aboul3la/Sublist3r/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
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
      sublister_domains = JSON.parse(http_get_body(search_uri))
      _log_good "Got sublister domains: #{sublister_domains}"
      sublister_domains.each{|d| _create_entity("DnsRecord", {"name" => "#{d}"})}
    rescue JSON::ParserError => e
      _log_error "Unable to get parsable response from #{search_uri}: #{e}"
    rescue StandardError => e
      _log_error "Error grabbing sublister domains: #{e}"
    end

  end

end
end
