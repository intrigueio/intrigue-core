module Intrigue
module Task
class SecurityTrailsNameserverSearch < BaseTask

  def self.metadata
    {
      :name => "security_trails_nameserver_search",
      :pretty_name => "Security Trails Nameserver Search",
      :authors => ["jcran"],
      :description => "This task hits the Security Trails API and finds all domains for a given nameserver.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord","IpAddress"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    begin
      total_records = []

      # get intial repsonse
      resp = get_records

      unless resp
        _log_error "unable to get a response"
        return
      end

      # check if we need to page
      max_pages = resp["meta"]["total_pages"]
      if max_pages > 1
        total_records = resp["records"]
        (2..max_pages).each do |p|

          resp = get_records(p)
          break unless resp

          total_records.concat(resp["records"])
        end
      # if not....
      else
        total_records = resp["records"]
      end

      # create entities
      total_records.each do |x|
        _create_entity "Domain", "name" => "#{x["hostname"]}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get a properly formatted response"
    end

  end # end run()

  def get_records(page=1)

    # Make sure the key and page are set
    api_key = _get_task_config "security_trails_api_key"
    entity_name = _get_entity_name
    uri = "https://api.securitytrails.com/v1/search/list?page=#{page}"

    # construct the query
    search_json = { "filter" => { "ns" =>  "#{entity_name}" } }.to_json

    # get the data
    resp = http_request(:post, uri, nil, {
      "apikey" => api_key,
      "content-type" => "application/json",
      "page" => page
      }, search_json)

    #handle the response
    if resp
      json_response = JSON.parse(resp.body)
      json_response["records"] = [] unless json_response["records"]
      _log "Got #{json_response["records"].count} domains!"
    else
      json_response = nil
    end

  json_response
  end

end
end
end
