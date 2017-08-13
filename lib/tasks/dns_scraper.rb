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
      sublister_domains = JSON.parse(http_get_body(search_uri))
      _log_good "Got sublister domains: #{sublister_domains}"
      sublister_domains.each{|d| _create_entity("DnsRecord", {"name" => "#{d}"})}
    rescue JSON::ParserError => e
      _log_error "Unable to get parsable response from #{search_uri}: #{e}"
    rescue StandardError => e
      _log_error "Error grabbing sublister domains: #{e}"
    end


    # Virustotal API (this'll be blocked after a couple queries... better to use the api)
    # API Docs: https://www.virustotal.com/en/documentation/public-api/#getting-domain-reports
    virustotal_uri = "https://www.virustotal.com/en/domain/#{search_domain}/information/"
    begin
      raw_html = http_get_body virustotal_uri
      html = Nokogiri::HTML(raw_html)
      vt_domains = html.xpath("//*[@id='observed-subdomains']/div/a/text()").map do |x|
        x.to_s.gsub("\n","").strip
      end
      _log_good "Got virustotal domains: #{vt_domains}"
      vt_domains.each{|d| _create_entity "DnsRecord", {"name" => "#{d}"} }
    rescue StandardError => e
      _log_error "Error grabbing virustotal domains: #{e}"
    end

  end

end
end
