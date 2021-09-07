  module Intrigue
  module Task
  class SearchAlienvaultOtx < BaseTask

    def self.metadata
      {
        :name => "threat/search_alienvault_otx",
        :pretty_name => "Threat Check - Search Alienvault OTX",
        :authors => ["Anas Ben Salah"],
        :description => "This task searches AlienVault OTX via API and checks for related Hostnames, IpAddresses",
        :references => ["https://otx.alienvault.com/api"],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["DnsRecord", "Domain", "IpAddress"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
        :allowed_options => [],
        :created_types => ["Domain", "IpAddress"]
      }
    end

    def run
      super

      # get entity details
      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("otx_api_key")

      headers = { 'Accept': 'application/json', 'X-OTX-API-KEY': api_key }

      if entity_type == "Domain" || entity_type == "DnsRecord"
        search_otx_by_hostname entity_name, headers
      elsif entity_type == "IpAddress"
        search_otx_by_ip entity_name, headers
      else
        _log_error "Unsupported entity type"
      end

    end #end run

    def search_otx_by_hostname entity_name, headers
      begin
        # get the initial repsonse for the a domain
        url = "https://otx.alienvault.com:443/api/v1/indicators/hostname/#{entity_name}/url_list"

        page_num = 1
        result = {"has_next" => true}

        while result["has_next"]

          # get the response, grab 50 at a time per alienvault docs
          response = http_get_body("#{url}?limit=50&page=#{page_num}", nil, headers)
          result = JSON.parse(response)

          # for each item in the url list, extarct Related IP from linked url
          result["url_list"].each do |u|
            if u && u["result"] && u["result"]["urlworker"] && u["result"]["urlworker"]["ip"]
              _create_entity "IpAddress", "name" => u["result"]["urlworker"]["ip"]
            else
              _log "Couldnt find: result/urlworker/ip... #{u}"
            end
          end

          # increment and repeate
          page_num += 1
        end

      rescue JSON::ParserError => e
        _log_error "unable to parse json!"
      end


    end # end search_hostname

    def search_otx_by_ip entity_name, headers
      begin

        # get the initial repsonse for domain_name
        url = "https://otx.alienvault.com:443/api/v1/indicators/IPv4/#{entity_name}/reputation"
        response = http_get_body("#{url}", nil, headers)
        result = JSON.parse(response)

          # return if response is null
          unless result["reputation"]
            _log "No reputation data found: #{result}"
            return
          end

          #for each item in the activites list, pull out the malicious ip and some related informations
          result["reputation"]["activities"].each do |u|
            _create_linked_issue("suspicious_activity_detected",{
              name: "Suspicious IP Flagged by OTX: #{_get_entity_name}",
              severity: result["reputation"]["threat_score"],
              detailed_description: "Alienvault OTX has this IP flagged as suspicious.",
              proof: u
            })
          end

      # handling json exceptions
      rescue JSON::ParserError => e
        _log_error "unable to parse json!"
      end

    end # end search_ip

  end # end Class
  end
  end
