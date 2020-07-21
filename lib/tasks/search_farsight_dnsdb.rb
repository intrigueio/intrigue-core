module Intrigue
  module Task
  class SearchFarsightDnsdb < BaseTask
  
    def self.metadata
      {
        :name => "search_farsight_dnsdb",
        :pretty_name => "Search Farsight DNSDB",
        :authors => ["jcran"],
        :description => "This task searches DNSDB by domain.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [
          {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types => ["DnsRecord"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      domain_name = _get_entity_name
      api_key = _get_task_config("farsight_dnsdb_api_key")
      api_url = "https://api.dnsdb.info/"
      headers = {"Accept" => "application/json", "X-API-Key" => api_key }
      
      #returns json, one per line 
      request_endpoint = "#{api_url}/lookup/rrset/name/\*.#{domain_name}?limit=0"
      out = http_get_body(request_endpoint, nil, headers)
      
      if out && out.kind_of?(String) && !out =~/^Error:/

        out.split("\n").each do |line|
          begin
            
            # Parse up the data 
            record = JSON.parse(line)
            rdata = record["rdata"]
            rdata.each do |dns_data|
              if !dns_data.split(" ").length > 1  # skip txt records and such
                create_dns_entity_from_string dns_data  
              end
            end

          rescue JSON::ParserError => e
            _log_error "Unable to parse line: #{line.first(50)}!"
          end  
        end

      else 
        _log_error "unable to parse result: #{out}"
      end

    end

  end
  end
  end
  