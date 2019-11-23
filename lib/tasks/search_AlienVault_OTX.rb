module Intrigue
module Task
class SearchAlienvaultOtx < BaseTask

 def self.metadata
   {
     :name => "search_alienvault_otx",
     :pretty_name => "Search Alienvault OTX",
     :authors => ["Anas Ben Salah"],
     :description => "This task hits AlienVault OTX API and checks for related hostnames, IpAddress and Hashes",
     :references => ["https://otx.alienvault.com/api"],
     :type => "discovery",
     :passive => true,
     :allowed_types => ["Domain","IpAddress","String"],
     :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
     :allowed_options => [],
     :created_types => ["Domain"]
   }
 end

 ## Default method, subclasses must override this
  def run

    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Make sure the key is set
    api_key = _get_task_config("otx_api_key")

    headers ={
      Accept: 'application/json',
      'X-OTX-API-KEY': api_key
    }

    if entity_type == "Domain"
      search_hostname entity_name,headers
    elsif entity_type == "IpAddress"
      search_ip entity_name,headers
    elsif entity_type == "String"
      search_hash entity_name,headers
    else
      _log_error "Unsupported entity type"
    end

  end #end run



  def search_hostname entity_name,headers

    begin

      # get the initial repsonse for domain_name
      url = "https://otx.alienvault.com:443/api/v1/indicators/hostname/#{entity_name}/url_list"
      response = http_get_body("#{url}?limit=50&page=1", headers: headers)
      json = JSON.parse(response)

      # for each item in the url list, extarct Related IP from linked url
      json["url_list"].each do |u|
        _create_entity "IpAddress", "name" => u["result"]["urlworker"]["ip"]
      end

      # if it's paged, cycle through all responses

      page_num = 2
      until json["has_next"] || json["url_list"]
        # get the response, grab 50 at a time per alienvault docs
        response = http_get_body("#{url}?limit=50&page=#{page_num}", headers: headers)
        json = JSON.parse(response)
        # for each item in the url list, extarct Related IP from linked url
        json["url_list"].each do |u|
        _create_entity "IpAddress", "name" => u["result"]["urlworker"]["ip"]
        end
      page_num = page_num + 1
      end
      #handling json exceptions
      rescue JSON::ParserError => e
        _log_error "unable to parse json!"
      end


  end # end search_hostname

  def search_ip entity_name,headers
    begin

      # get the initial repsonse for domain_name
      url = "https://otx.alienvault.com:443/api/v1/indicators/IPv4/#{entity_name}/reputation"
      response = http_get_body("#{url}", headers: headers)
      json = JSON.parse(response)

        # return if response is null
        if json["reputation"]== "null"
          return
        end

        #for each item in the activites list, pull out the malicious ip and some related informations
        json["reputation"]["activities"].each do |u|

          _create_issue({
              name: "Malicious IP Flagged by OTX :  #{_get_entity_name}",
              type: "Malicious IP",
              severity: json["reputation"]["threat_score"],
              status: "confirmed",
              description: "[Location]: #{json["reputation"]["country"]}\n" + "[Last seen]: #{json["reputation"]["last_seen"]}\n" + "[Activities]:\n" + "{[NAME]: #{u["name"]}\n" + "[SOURCE]: #{u["source"]}",
              details: json
            })

         end

    # handling json exceptions
    rescue JSON::ParserError => e
      _log_error "unable to parse json!"
    end

  end # end search_ip


  def search_hash entity_name,headers
    begin

      # get the initial repsonse for domain_name
      url = "https://otx.alienvault.com/api/v1/indicators/file/#{entity_name}/general"
      response = http_get_body("#{url}", headers: headers)
      json = JSON.parse(response)

      # return if response is null
      if json["pulse_info"]["count"]== 0
        return
      end
      i=1
      #for each item in the activites list, Create issue and pull out the malicious File and some related informations
      json["pulse_info"]["pulses"].each do |e|

        _create_issue({
            name: "#{i}: Malicious File Flagged by OTX",
            type: "Malicious File",
            severity: 3,
            status: "confirmed",
            description: "#{json["pulse_info"]["count"]} pulse found in alienvault with this description:#{e["description"]} || [References]:#{json["pulse_info"]["references"]}",
            details: json
          })
        i += 1
       end

      #handling json exceptions
      rescue JSON::ParserError => e
        _log_error "unable to parse json!"
      end

  end #end search_hash

end # end Class
end
end
