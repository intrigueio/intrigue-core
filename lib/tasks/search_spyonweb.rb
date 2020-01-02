module Intrigue
  module Task
  class SearchSpyOnWeb < BaseTask

    def self.metadata
      {
        :name => "search_spyonweb",
        :pretty_name => "Search SpyOnWeb",
        :authors => ["AnasBenSalah"],
        :description => "This task hits the SpyOnWEB API for hosts sharing the same IP address, domains, Google Analytics code, or Google Adsense code.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["IpAddress", "Domain", "AnalyticsId"],
        :example_entities => [{"type" => "IpAddress", "details" => {"name" => "192.0.78.13"}}],
        :allowed_options => [],
        :created_types => ["IpAddress","AnalyticsId", "DnsRecord"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("spyonweb_api_key")

      if entity_type == "IpAddress"
        search_ip entity_name, api_key
      elsif entity_type == "Domain"
        search_domain entity_name, api_key
      elsif entity_type == "AnalyticsId"
        search_adsense(entity_name, api_key) if entity_name =~ /^pub-\d*/i
        search_analytics(entity_name,api_key) if entity_name =~ /^UA-\d*/i 
      else
        _log_error "Unsupported entity type"
      end
    end #end run


    def search_ip(entity_name,api_key)
      begin

        # formulate and make the request
        url = "https://api.spyonweb.com/v1/ip/#{entity_name}?access_token=#{api_key}"

        response = http_get_body url
        json = JSON.parse(response)

        # core
        if json["status"] == "found"

          #create sahred adsense of the specific domain
          json["result"]["ip"]["#{entity_name}"]["items"].each do |u|

              _create_entity "DnsRecord" , "name" => u[0]

          end
        end

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end # end run

    def search_domain(entity_name,api_key)

      begin

        url = "https://api.spyonweb.com/v1/domain/#{entity_name}?access_token=#{api_key}"

        response = http_get_body url
        json = JSON.parse(response)

        #Check if spyonweb API has data about the domain
        if json["status"] == "found"

          #create shared absense of the specific domain
          if json["result"]["domain"]["#{entity_name}"]["items"]["adsense"]

              json["result"]["domain"]["#{entity_name}"]["items"]["adsense"].each do |u|
                  _create_entity "AnalyticsId" , "name" => u[0]
              end

          end

          #Create shared analytics of the specific domain
          if json["result"]["domain"]["#{entity_name}"]["items"]["analytics"]

            json["result"]["domain"]["#{entity_name}"]["items"]["analytics"].each do |u|
                _create_entity "AnalyticsId" , "name" => u[0]
            end

          end

          #create shared DNS record and IPs of the specific domain
          if json["result"]["domain"]["#{entity_name}"]["items"]["dns_servers"]

            json["result"]["domain"]["#{entity_name}"]["items"]["dns_servers"].each do |u|
                _create_entity "DnsRecord" , "name" => u[0]
                _create_entity "IpAddress" ,"name" => u[1]
            end

          end

      end

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end


    #Search for DNS record share the same google analytics id
    def search_analytics(entity_name,api_key)

      begin

        url = "https://api.spyonweb.com/v1/analytics/#{entity_name.upcase}?access_token=#{api_key}"

        response = http_get_body url
        json = JSON.parse(response)

        #Check if spyonweb API has data about the google analytics ID
        if json["status"] == "found"

          #create DnsRecord for domain share the specific google analytics id
          json["result"]["analytics"]["#{entity_name.upcase}"]["items"].each do |u|

              _create_entity "DnsRecord" , "name" => u[0]

          end
        end

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end

    end

    #Search for DNS record share the same google adsense id
    def search_adsense(entity_name,api_key)

      begin

        url = "https://api.spyonweb.com/v1/adsense/#{entity_name}?access_token=#{api_key}"

        response = http_get_body url
        json = JSON.parse(response)

        #Check if spyonweb API has data about the google adsense ID
        if json["status"] == "found"

          #create DnsRecord for domain share the specific google analytics id
          json["result"]["adsense"]["#{entity_name}"]["items"].each do |u|

            _create_entity "DnsRecord" , "name" => u[0]

          end
        end

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end


end
end
end
