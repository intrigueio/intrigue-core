module Intrigue
module Task
class SearchSpyse < BaseTask

  def self.metadata
    {
      :name => "search_spyse",
      :pretty_name => "Search Spyse",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Spyse API for subdomains, IP / Port lookup, DNS records and SslCertificate information",
      :references => ["https://spyse.com/apidocs"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress","String", "Domain", "NetBlock"],
      :example_entities => [{"type" => "String", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","IpAddress","Organization","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Make sure the key is set
    api_key = _get_task_config("spyse_api_key")
    # Set the headers
    headers = { "Accept" =>  "application/json", 
      "Authorization" => "Bearer #{api_key}"}

    case entity_type
    when 'IpAddress'
      search_open_ports(entity_name, headers)
    when 'NetBlock'
      search_ip_via_netblock(entity_name, headers)
    else
      _log_error 'Entity not supported'
    end

  end #end

  def search_ip_via_netblock(entity_name, headers)
    results = []

    ip_addresses = expand_netblock(entity_name)
    headers['Content-Type'] = 'application/json'

    until ip_addresses.empty?
      ip_set = ip_addresses.pop(100)
      post_body = JSON.dump({ 'ip_list': ip_set })
      r = http_request(:post, 'https://api.spyse.com/v4/data/bulk-search/ip', nil, headers, post_body)

      json_parsed = _parse_json_response(r.body)
      next if json_parsed.nil?

      next unless json_parsed['data']
      next unless json_parsed['data']['items']

      json_parsed['data']['items'].each do |item|
        ip_address = item['ip']
        ports = item['ports']&.map { |port| port['port'] }
        results << { 'ip' => ip_address, 'ports' => ports&.compact }
      end
    end
    _create_result_entities(results)
  end

  def _create_result_entities(results)
    results.each do |r|
      next if r['ports'].nil?

      e = _create_entity 'IpAddress', { 'name' => r['ip'] }
      r['ports'].each { |pr| _create_network_service_entity(e, pr, 'tcp') }
    end
  end


  def _parse_json_response(response)
    JSON.parse(response)
  rescue JSON::ParserError
    _log_error 'Issue parsing JSON'
  end

  # Search IP reputation and gathering data
  def search_ip_reputation(entity_name, headers)

    # Set the URL for ip data
    url = "https://api.spyse.com/v2/data/ip?limit=100&ip=#{entity_name}"

    begin 
      # make the request
      response = http_get_body(url,nil,headers)
      json = JSON.parse(response)

      json["data"]["items"].each do |result|

        # Create an issue if result score indicates a score related to the threat
        if result["score"] < 100
          _create_linked_issue("suspicious_activity_detected",{
            proof: result,
            severity: result["score"],
            references: ["https://spyse.com/"],
            source: "Spyse",
            details: result
          })
        end

      end
    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end
  end

  # Search for open ports
  def search_open_ports entity_name, headers

    # Set the URL for ip open ports
    url = "https://api.spyse.com/v3/data/ip/port?limit=100&ip=#{entity_name}"

    begin 
      # make the request
      response = http_get_body(url, nil, headers)
      json = JSON.parse(response)

      if json["data"] && json["data"]["items"]
        json["data"]["items"].each do |result|
          _log_good "Creating service on #{entity_name}: #{result["port"]}"
          begin
            _create_network_service_entity(@entity, result["port"], protocol="tcp", 
              {"extended_spyse" => result})
          rescue Errno::ETIMEDOUT
            _log_error "Unable to create network service entity. Connection timed out."
          end
        end
      else
        _log "Got empty result, returning!"
      end
    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end
    
  end

end
end
end
