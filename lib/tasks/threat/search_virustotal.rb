module Intrigue
module Task
class SearchVirustotal < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "threat/search_virustotal",
      :pretty_name => "Threat Check - Search VirusTotal",
      :authors => ["jcran"],
      :description => "This task hits VirusTotal's API and creates new DnsRecord entities.",
      :references => ["https://www.virustotal.com/en/documentation/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [ {"type" => "DnsRecord", "details" => {"name" => "intrigue"}} ],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    search_domain = _get_entity_name

    # Virustotal API (this'll be blocked after a couple queries... need to move this to the api)
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
end
