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

    if result["status"] = "403"
      raise InvalidTaskConfigurationError, "Got message: #{result}"
    end

  result
  end

  def search_binaryedge_by_subdomain(entity_name, api_key)
    begin

      # get the initial results (page 1)
      uri = "https://api.binaryedge.io/v2/query/domains/subdomain/#{entity_name}"
      result = JSON.parse(http_request(:get, uri+"?page=1", nil, {"X-Key" =>  "#{api_key}"} ).body)

      if result["status"] = "403"
        raise InvalidTaskConfigurationError, "Got message: #{result}"
      end

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
        
        if result["status"] = "403"
          raise InvalidTaskConfigurationError, "Got message: #{result}"
        end


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

      if result["status"] = "403"
        raise InvalidTaskConfigurationError, "Got message: #{result}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  result
  end


  def search_binaryedge_leaks_by_email_address(entity_name, api_key)
    begin

      uri = "https://api.binaryedge.io/v2/query/dataleaks/email/#{entity_name}"
      result = JSON.parse(http_request(:get, uri, nil, {"X-Key" =>  "#{api_key}"}).body)

      if result["status"] = "403"
        raise InvalidTaskConfigurationError, "Got message: #{result}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end

  result
  end

  def search_binaryedge_string_query(query,headers,entity_name,page_num)
    # get the results
    uri = "https://api.binaryedge.io/v2/query/search?query=#{query}%20AND%20#{entity_name}&page=#{page_num}"
    begin 
      result = JSON.parse(http_request(:get, uri, nil, headers).body)
    rescue JSON::ParserError => e 
      _log_error "unable to parse results"
    end

    if result["status"] = "403"
      raise InvalidTaskConfigurationError, "Got message: #{result}"
    end

  result["events"]
  end

  def search_binaryedge_netblock(netblock,api_key,page_num = 0)
    # get the results
    uri = "https://api.binaryedge.io/v2/query/search?query=\"ip:#{netblock}\"&page=#{page_num}"
    headers = {"X-Key" =>  "#{api_key}"}
    begin 
      result = http_request(:get, uri, nil, headers)
      result_json = JSON.parse(result.body_utf8)
    rescue JSON::ParserError => e 
      _log_error "unable to parse results"
    end    

    if result.response_code == 403
      raise InvalidTaskConfigurationError, "Got message: #{result_json}"
    end

  result_json["events"]
  end

  ###
  ### Parsing for results 
  ### 
  def check_elastic_results(result)
    result.each do |service|
      uri ="http://#{service['target']['ip']}:#{service['target']['port']}/_cat/indices"
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      if service['result']['data']['indices']
        service['result']['data']['indices'].each do |indice|
          _create_linked_issue("open_database",{
           proof: service,
           source:"binaryedge" ,
           description: "
           Link: http://#{service['target']['ip']}:#{service['target']['port']}/_cat/indices \n
           Cluster name: #{service['result']['data']['cluster_name']}\n
           Indices:\n
           Name: #{indice['index_name']} \n
           No. of documents: #{indice['docs']}\n
           Size: #{indice['size_in_bytes']}",
           references: ["https://binaryedge.com/"],
           details: service
        },e)
        end
      else
        _create_linked_issue("open_database",{
          proof: service,
          source: "binaryedge" ,
          description: "
          Link: http://#{service['target']['ip']}:#{service['target']['port']}/_cat/indices \n
          Cluster name: #{service['result']['data']['cluster_name']}\n",
          references: ["https://binaryedge.com/"],
          details: service
        },e)
      end
    end
  end

  def check_kibana_results(result)
    result.each do |service|
      uri ="http://#{service['target']['ip']}:#{service['target']['port']}/app/kibana#/discover?_g=()"
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge" ,
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}/app/kibana#/discover?_g=()\n
        Server status: #{service['result']['data']['state']['state']}\n",
        references: ["https://binaryedge.com/"],
        details: service
      },e)
    end
  end

  def check_jenkins_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
        state: open ",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_gitlab_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      html_code = service['result']['data']['response']['body']
      if html_code.include? "register"
        _create_linked_issue("open_database",{
          proof: service,
          source: "binaryedge",
          description: "
          Link: https://#{service['target']['ip']}:#{service['target']['port']}\n
          state: Registration is open ",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      else
        _create_linked_issue("open_database",{
          proof: service,
          source: "binaryedge",
          severity: 5,
          description: "
          Link: https://#{service['target']['ip']}:#{service['target']['port']}/explore\n
          state: Registration is closed",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      end
    end
  end

  def check_rsync_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
        Server status :#{service['result']['data']['state']['state']}",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_sonarqube_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      if service['result']['data']['response']['redirects']
        _create_linked_issue("open_database",{
          proof: service,
          source: "binaryedge",
          description: "
          Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
          Server: Authentication required",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      else
        _create_linked_issue("open_database",{
          proof: service,
          source: "binaryedge",
          description: "
          Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
          Server: Can't retrieve details",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      end
    end
  end

  def check_mongodb_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_cassandra_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
        Cluster name: #{service['result']['data']['info'][0]['cluster_name']}
        Datacenter: #{service['result']['data']['info'][0]['data_center']}",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_couchdb_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "Link: http://#{service['target']['ip']}:#{service['target']['port']}/_utils",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_rethinkdb_results(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        proof: service,
        source: "binaryedge",
        description: "
        ReQL: #{service['target']['ip']}:#{service['result']['data']['status'][0]['network']['reql_port']}
        HTTP Admin: http://#{service['target']['ip']}:#{service['result']['data']['status'][0]['network']['http_admin_port']}",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end


end
end
end
