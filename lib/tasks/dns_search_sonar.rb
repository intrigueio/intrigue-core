module Intrigue
module Task
class DnsSearchSonar < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "dns_search_sonar",
      :pretty_name => "DNS Search Sonar",
      :authors => ["jcran", "erbbysam"],
      :description => "Search Rapid7's Project Sonar for FDNS and RDNS records matching a given pattern. Utilizes @erbbysam's excellent DNSGrep server to serve results.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","Domain"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "endpoint", :regex => "alpha_numeric_list", :default => "http://sonar.intrigue.io/dns?q=" },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    endpoint = _get_option("endpoint")
    domain_name = ".#{_get_entity_name}"
    search_url = "#{endpoint}#{domain_name}"
    _log_good "Searching data for: #{domain_name}"
    
    response = http_request(:get, search_url, nil, {}, nil, true, 60)
    unless response
      _log_error "Unable to get a response. Is the server up?"
      return false
    end

    begin
      json = JSON.parse(response.body_utf8)

      # Create forward dns entries
      if json["FDNS_A"]
        json["FDNS_A"].each do |entry|
          # format: "199.34.228.55,red-buddha-american-apparel-llc.company.com",
          next if entry.split(",").last =~ /mail\.mail/
          create_dns_entity_from_string(entry.split(",").last)
        end
      end

      # Create reverse dns entries
      if json["RDNS"]
        json["RDNS"].each do |entry|
          # format: "199.34.228.55,red-buddha-american-apparel-llc.company.com",
          create_dns_entity_from_string(entry.split(",").last)
        end
      end

    rescue JSON::ParserError => e
      _log_error "Unable to parse"
    end

  end

end
end
end
