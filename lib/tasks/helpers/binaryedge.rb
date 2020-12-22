module Intrigue
module Task
module BinaryEdge


  def search_binaryedge_by_ip(entity_name, api_key)
    begin
      # formulate and make the request
      uri = "https://api.binaryedge.io/v2/query/ip/#{entity_name}"
      result = JSON.parse(http_request(:get, uri, nil, {"X-Key" =>  "#{api_key}" }).body)

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  result
  end

  def search_binaryedge_by_subdomain(entity_name, api_key)
    begin

      # get the initial results (page 1)
      uri = "https://api.binaryedge.io/v2/query/domains/subdomain/#{entity_name}"
      result = JSON.parse(http_request(:get, uri+"?page=1", nil, {"X-Key" =>  "#{api_key}"} ).body)

      page_num = 1
      record_count = result["pagesize"]
      total_record_count = result["total"]

      dns_records = []
      while record_count < total_record_count

        # for every result, dunmp it into our array
        result["events"].each do |d|
          dns_records << d
        end

        record_count += result["pagesize"]
        page_num += 1

        # make another request ... TODO ... DRY this up
        result = JSON.parse(http_request(:get, uri+"?page=#{page_num}", nil, {"X-Key" =>  "#{api_key}" }).body)

      end
    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end

  dns_records
  end #

  def search_binaryedge_leaks_by_domain(entity_name, api_key)
    begin
      url = "https://api.binaryedge.io/v2/query/dataleaks/organization/#{entity_name}"
      result = JSON.parse(http_request(:get, url, nil, {"X-Key" =>  "#{api_key}" }).body)
    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  result
  end


  def search_binaryedge_leaks_by_email_address(entity_name, api_key)
    begin

      uri = "https://api.binaryedge.io/v2/query/dataleaks/email/#{entity_name}"
      result = JSON.parse(http_request(:get, uri, nil, {"X-Key" =>  "#{api_key}"}).body)

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end

  result
  end

  def binaryedge_query(query,headers,entity_name,page_num)
    # get the results
    uri = "https://api.binaryedge.io/v2/query/search?query=#{query}%20AND%20#{entity_name}&page=#{page_num}"
    json = JSON.parse(http_request(:get, uri, nil, headers).body)
    return json["events"]
  end


end
end
end
