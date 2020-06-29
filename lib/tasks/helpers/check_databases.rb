module Intrigue
module Task
module CheckDatabase


  def check_elastic(result)
    result.each do |service|
      uri ="http://#{service['target']['ip']}:#{service['target']['port']}/_cat/indices"
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      if service['result']['data']['indices']
        service['result']['data']['indices'].each do |indice|
          _create_linked_issue("open_database",{
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

  def check_kibana(result)
    result.each do |service|
      uri ="http://#{service['target']['ip']}:#{service['target']['port']}/app/kibana#/discover?_g=()"
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        source: "binaryedge" ,
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}/app/kibana#/discover?_g=()\n
        Server status: #{service['result']['data']['state']['state']}\n",
        references: ["https://binaryedge.com/"],
        details: service
      },e)
    end
  end

  def check_jenkins(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
        state: open ",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_gitlab(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      html_code = service['result']['data']['response']['body']
      if html_code.include? "register"
        _create_linked_issue("open_database",{
          source: "binaryedge",
          description: "
          Link: https://#{service['target']['ip']}:#{service['target']['port']}\n
          state: Registration is open ",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      else
        _create_linked_issue("open_database",{
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

  def check_rsync(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      _create_linked_issue("open_database",{
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
        Server status :#{service['result']['data']['state']['state']}",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_sonarqube(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })
      if service['result']['data']['response']['redirects']
        _create_linked_issue("open_database",{
          source: "binaryedge",
          description: "
          Link: http://#{service['target']['ip']}:#{service['target']['port']}\n
          Server: Authentication required",
          references: ["https://binaryedge.com/"],
          details: service
          },e)
      else
        _create_linked_issue("open_database",{
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

  def check_mongodb(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        source: "binaryedge",
        description: "
        Link: http://#{service['target']['ip']}:#{service['target']['port']}\n",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_cassandra(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
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

  def check_couchdb(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        source: "binaryedge",
        description: "Link: http://#{service['target']['ip']}:#{service['target']['port']}/_utils",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_rethinkdb(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
        source: "binaryedge",
        description: "
        ReQL: #{service['target']['ip']}:#{service['result']['data']['status'][0]['network']['reql_port']}
        HTTP Admin: http://#{service['target']['ip']}:#{service['result']['data']['status'][0]['network']['http_admin_port']}",
        references: ["https://binaryedge.com/"],
        details: service
        },e)
    end
  end

  def check_rethinkdb(result)
    result.each do |service|
      e =_create_entity("IpAddress", {"name" => "#{service['target']['ip']}" })

      _create_linked_issue("open_database",{
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
