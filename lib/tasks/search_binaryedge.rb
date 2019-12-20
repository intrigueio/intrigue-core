module Intrigue
  module Task
  class SearchBinaryEdge < BaseTask
  
    def self.metadata
      {
        :name => "search_binaryedge",
        :pretty_name => "Search BinaryEdge",
        :authors => ["jcran","AnasBenSalah"],
        :description => "This task hits the BinaryEdge API for a given IpAddress, Domain, " +
        "or Email Address, and returns data that BinaryEdge has, including ports, torrents, " +
        "and checks for maliciousness",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["IpAddress", "Domain", "EmailAddress"],
        :example_entities => [],
        :allowed_options => [],
        :created_types => ["NetworkService","Uri", "DnsRecord"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("binary_edge_api_key")
      @headers = {"X-Key" =>  "#{api_key}" }
  
      if entity_type == "IpAddress"
         search_ip entity_name
         search_ip_score entity_name
      elsif entity_type == "Domain"
         search_subdomain entity_name
      elsif entity_type == "EmailAddress"
         search_emailaddress entity_name
      else
         _log_error "Unsupported entity type"
      end
  
    end #end run
  
  
    def search_ip(entity_name)
      begin
  
        # formulate and make the request
        uri = "https://api.binaryedge.io/v2/query/ip/#{entity_name}"
        json = JSON.parse(http_request(:get, uri, nil, @headers).body)
  
        if json["events"]
          json["events"].each do |e|
  
            e["results"].each do |r|
  
              _create_network_service_entity(@entity, r["target"]["port"],
                  r["target"]["protocol"], {"binary_edge" => e})
  
              # this should be optional...
              if e["port"] != "443"
                    _create_issue({
                name: "#{entity_name}:#{e["port"]}  [Binary Edge]",
                type: "Malicious IP",
                severity: 3 ,
                status: "confirmed",
                description: "Port: #{e["port"]} || State:#{r["result"]["data"]["state"]} || Security issue:#{r["result"]["data"]["security"]}
                || Reason:#{r["result"]["data"]["reason"]} || ",#Running Service:#{r["result"]["data"]["service"]}",
                details: json
                })
              end
  
            end
          end
        end
      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end # end run
  
  
    def search_subdomain(entity_name)
      begin

        uri = "https://api.binaryedge.io/v2/query/domains/subdomain/#{entity_name}"
        json = JSON.parse(http_request(:get, uri+"?page=1", nil, @headers).body)
        i = json["pagesize"]
        page_num = 1
        while i < json["total"]
          json["events"].each do |u|
            _create_entity "DnsRecord" , "name" => u
          end
          i += json["pagesize"]
          page_num += 1
          uri = "https://api.binaryedge.io/v2/query/domains/subdomain/#{entity_name}"
          json = JSON.parse(http_request(:get, uri+"?page=#{page_num}", nil, @headers).body)
          json["events"].each do |u|
            _create_entity "DnsRecord" , "name" => u
          end
        end
  
        uri2 = "https://api.binaryedge.io/v2/query/dataleaks/organization/#{entity_name}"
        json2 = JSON.parse(http_request(:get, uri2, nil, headers).body)
  
        if json2["total"] == 0
            return
          end
  
        json2["groups"].each do |t|
  
          _create_issue({
            name: "leak found related to: #{entity_name} in #{t["leak"]}",
            type: "Data leak",
            severity: 4 ,
            status: "confirmed",
            description: "#{t["count"]} accounts found related to #{entity_name} in #{t["leak"]}",
            references:"https://binaryedge.com/",
            details: json2["groups"]
  
          }
          )
  
        end
  
      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end #
  
  
  def search_emailaddress(entity_name)
    begin
  
      uri = "https://api.binaryedge.io/v2/query/dataleaks/email/#{entity_name}"
      json = JSON.parse(http_request(:get, uri, nil, @headers).body)
  
          if json["total"] == 0
              return
            end
  
      json["events"].each do |u|
        _create_issue({
           name: "Email found in Data leak: #{entity_name} in #{u}",
           type: "Leacked E-mail Address",
           severity: 3 ,
           status: "confirmed",
           description: "This Email has been found in this breach:#{u}",
           references:"https://binaryedge.com/",
           details: json
         })
      end
  
      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end
  
  end
  end
end  