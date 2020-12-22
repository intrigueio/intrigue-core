module Intrigue
  module Task
  class SearchHostio < BaseTask

    def self.metadata
      {
        :name => "search_Hostio",
        :pretty_name => "Search Hostio",
        :authors => ["Anas Ben Salah"],
        :description => "This task hits the Host.io API for Metadata scraped from a domain homepage, DNS records, AnalyticsId and related domains",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
        :allowed_options => [],
        :created_types => ["IpAddress","UniqueToken", "DnsRecord", "EmailAddress", "Domain"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("Hostio_api_key")

      if entity_type == "Domain"
        search_analyticsid entity_name, api_key
      else
        _log_error "Unsupported entity type"
      end
    end #end run


    #Search domain name for google AnalyticsID, AdSense, IPs, and Email Address
    def search_analyticsid(entity_name,api_key)

      begin

        url = "https://host.io/api/web/#{entity_name}?token=#{api_key}"
        response = http_get_body url
        json = JSON.parse(response)

        #Check if host.io has data about the google analytics ID
        if json["googleanalytics"]
          # Create shared analytics of the specific domain
          _create_entity "UniqueToken" , "name" => json["googleanalytics"]
          google_analyticsid = json["googleanalytics"]
          # List domains share the same Google Analytics tracking ID
          search_domains_related_to_same_googleanalytics google_analyticsid, api_key
        end

        #Check if host.io has data about Google AdSense publisher ID
        if json["adsense"]
          # Create shared analytics of the specific domain
          _create_entity "UniqueToken" , "name" => json["adsense"]
          google_adsenseid = json["adsense"]
          # list domains share the same Google AdSense publisher ID
          search_domains_related_to_same_googleadsense google_adsenseid, api_key
        end

        # Get Extra Data

        # Get scarped Email from domain name
        if json["email"]
          _create_entity "EmailAddress" , "name" => json["email"]
        end

        # Get IpAddres scarped from domain name
        if json["ip"]
          _create_entity "IpAddress" , "name" => json["ip"]
        end

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end

    end

    # search_domains_related_to_same_analyticsid
    def search_domains_related_to_same_googleanalytics (google_analyticsid, api_key)
      url = "https://host.io/api/domains/googleanalytics/#{google_analyticsid}?limit=100&token=#{api_key}"
      response = http_get_body url
      json = JSON.parse(response)

      if json["domains"]
        json["domains"].each do |u|
          #_create_entity "DnsRecord" , "name" => u
           create_dns_entity_from_string u
        end
      end
    end

    # search_domains_related_to_same_adsense analyticsid
    def search_domains_related_to_same_googleadsense (google_adsenseid, api_key)
      url = "https://host.io/api/domains/googleanalytics/#{google_adsenseid}?limit=100&token=#{api_key}"
      response = http_get_body url
      json = JSON.parse(response)

      if json["domains"]
        json["domains"].each do |u|
          #_create_entity "DnsRecord" , "name" => u
          create_dns_entity_from_string u
        end
      end
    end

end
end
end
