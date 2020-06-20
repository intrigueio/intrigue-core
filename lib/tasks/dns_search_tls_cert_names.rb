module Intrigue
  module Task
  class DnsSearchTlsCertnames < BaseTask
  
    include Intrigue::Task::Web
  
    def self.metadata
      {
        :name => "dns_search_tls_cert_names",
        :pretty_name => "DNS Search TLS Cert Names",
        :authors => ["jcran", "erbbysam"],
        :description => "Search @erbbysam's TLS Cert repository (gathered from connecting for matches.",
        :references => ["https://cdn.shopify.com/s/files/1/0177/9886/files/phv2019-serb.pdf"],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["DnsRecord", "Domain"],
        :example_entities => [{"type" => "domain", "details" => {"name" => "acme.com"}}],
        :allowed_options => [
          {:name => "endpoint", :regex => "alpha_numeric_list", :default => "https://tls.bufferover.run/dns?q=" },
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
      
      response = http_request(:get, search_url, nil, {}, nil, 3, 60, 60)
      unless response
        _log_error "Unable to get a response. Is the server up?"
        return false
      end
  
      begin
        json = JSON.parse(response.body)
  
        # Create forward dns entries
        if json["Results"]
          json["Results"].each do |entry|
            # format: "54.201.204.183,,blog.erbbysam.com"
            hostname = entry.split(",").last
            create_dns_entity_from_string(hostname)
          end
        end
  
      rescue JSON::ParserError => e
        _log_error "Unable to parse"
      end
  
    end
  
  end
  end
  end
  