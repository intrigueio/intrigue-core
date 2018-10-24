module Intrigue
module Task
module SecurityTrails

  def st_nameserver_search(entity_name,page=1)

    # Make sure the key and page are set
    api_key = _get_task_config "security_trails_api_key"

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