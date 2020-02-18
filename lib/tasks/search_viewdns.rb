module Intrigue
module Task
class SearchViewdns < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_viewdns_reverse_whois",
      :pretty_name => "Search ViewDNS (Reverse Whois)",
      :authors => ["jcran"],
      :description => "This task hits the ViewDNS API and returns records that match WHOIS data.",
      :references => ["https://viewdns.info/reversewhois/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain", "EmailAddress", "Organization", "Person"],
      :example_entities => [ {"type" => "Organization", "details" => {"name" => "Intrigue Corp"}} ],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
  end

  def run
    super

    search_string = _get_entity_name
    api_key = _get_task_config "viewdns_api_key"

    page = 1 
    max_pages = 1
    # always enter the loop
    while page <= max_pages

      # do the first query and set max_pages so we know how many to lop[]
      _log "Getting results from page: #{page}"
      json = query_viewdns_api(search_string, api_key, page)
      max_pages = json["response"]["total_pages"].to_i
      
      # for each of the domain matches.. 
      json["response"]["matches"].each do |m|
        # create the domain
        _create_entity "Domain", { 
          "name" => m["domain"], 
          "viewdns_info" => {
            "created_date" => m["created_date"], 
            "registrar" => m["registrar"] 
          }
        }
      end 

      page += 1
    end
  end

  # Helper function to query thte api 
  def query_viewdns_api(query,key,page=1)
    url = "https://api.viewdns.info/reversewhois/?output=json&apikey=#{key}&page=#{page}&q=#{query}"
    begin
      response = http_get_body(url)
      json = JSON.parse(response) 
    rescue JSON::ParserError => e
      _log_error "Unable to parse response: #{response}" 
    end
  json
  end

end
end
end
