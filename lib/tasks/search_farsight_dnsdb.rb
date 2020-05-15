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
        :created_types => ["*"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      name = _get_entity_name
      api_key = _get_task_config("farsight_dnsdb_api_key")
      api_endpoint = "https://api.dnsdb.info/"

      #curl -i -H 'Accept: application/json' -H "" 

      headers = {"Accept" => "application/json", "X-API-Key" => api_key }
      
      #returns json, one per line 
      out = http_get_body("#{api_endpoint}/lookup/rrset/name/\*.#{_get_entity_name}?limit=0", nil, headers)
      
      if out && out.kind_of?(String) && !out =~/^Error:/

        out.split("\n").each do |line|
          begin
            
            # parse the line into a record 
            record = JSON.parse(line)

            # grab the dns name, remove trailing space and wildcards
            create_dns_entity_from_string dns_name
  
            # Parse up the data 
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
  