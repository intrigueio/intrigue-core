###
### Please note - these methods may be used inside task modules, or inside libraries within
### Intrigue. An attempt has been made to make them abstract enough to use anywhere inside the
### application, but they are primarily designed as helpers for tasks. This is why you'll see
### references to @task_result in these methods. We do need to check to make sure it's available before
### writing to it.
###

# This module exists for common web functionality
module Intrigue
module Task
module Services

  include Intrigue::Task::Web

  def _create_network_service_entity(ip_entity,port_num,protocol="tcp",generic_details={})

    # first, save the port details on the ip_entity
    ports = ip_entity.get_detail("ports") || []
    updated_ports = ports.append({"number" => port_num, "protocol" => protocol}).uniq
    ip_entity.set_detail("ports", updated_ports)

    ssl = true if [443, 8443].include?(port_num)

    # Ensure we always save our host and key details.
    # note that we might add service specifics to this below
    generic_details.merge!({
      "port" => port_num,
      "ssl" => ssl,
      "protocol" => protocol,
      "ip_address" => ip_entity.name,
      "asn" => ip_entity.get_detail("asn"),
      "host_id" => ip_entity.id
    })

    # if this is an ssl port, let's get the CNs and create
    # dns records
    cert_entities = []
    if ssl
      # connect, grab the socket and make sure we
      # keep track of these details, and create entitie
      cert_names = connect_ssl_socket_get_cert_names(ip_entity.name,port_num)
      if cert_names
        generic_details.merge!({"alt_names" => cert_names})
        cert_names.uniq do |cn|

          if entity_exists?(ip_entity.project, "DnsRecord", cn)
            _log "Skipping entity creation for DnsRecord#{cn}, already exists"
            next 
          end

          # unscope, bc we don't want to scope in the hosting company ... 
          cert_entities << _create_entity("DnsRecord", { "name" => cn,
            "unscoped" => true }, ip_entity) 
          
        end
      end
    end

    # Grab all the aliases, since we'll want to auto-create services on them
    # (VHOSTS use case)
    hosts = [ip_entity].concat cert_entities.uniq
    if ip_entity.aliases.count > 0
      ip_entity.aliases.each do |a|
        next unless a.type_string == "DnsRecord" #  only dns records
        next if a.hidden # skip hidden
        hosts << a # add to the list
      end
    end
    _log "Creating services on each of: #{hosts.map{|h| h.name } }"

    sister_entity = nil
    thread_list = []
    hosts.uniq.each do |h|
      thread_list << Thread.new do 

        # Handle web app case first
        if (protocol == "tcp" && [80,81,443,8000,8080,8081,8443].include?(port_num))

          # If SSL, use the appropriate prefix
          prefix = ssl ? "https" : "http" # construct uri

          # Construct the uri
          uri = "#{prefix}://#{h.name}:#{port_num}"


          # if we've never seen this before, go ahead and open it to ensure it's 
          # something we want to create (this helps eliminate unusable urls). However, 
          # skip if we have, we want to minimize requests to the services
          if !entity_exists? ip_entity.project, "Uri", uri

            x = _gather_http_response(uri)
            http_response = x[:http_response]
            generic_details.merge!(x[:extra_details])

            unless http_response
              _log_error "Didn't get a response when we requested one, moving on"
              next
            end
          end

          entity_details = {
            "name" => uri,
            "uri" => uri,
            "service" => prefix
          }.merge!(generic_details)

          # Create entity and track this entity so we can manage a group of aliases (called sisters here)
          sister_entity = _create_entity("Uri", entity_details, sister_entity)

        # otherwise, create a network service on the IP, either UDP or TCP - fail otherwise
        elsif protocol == "tcp" && h.name.is_ip_address?

          service_specific_details = {}

          case port_num
            when 21
              service = "FTP"
            when 22,2222
              service = "SSH"
            when 23
              service = "TELNET"
            when 25
              service = "SMTP"
            when 53
              service = "DNS"
            when 79
              service = "FINGER"
            when 110
              service = "POP3"
            when 111
              service = "SUNRPC"
            when 502,503
              service = "MODBUS"
            when 1883
              service = "MQLSDP"
            when 2181,2888,3888
              service = "ZOOKEEPER"
            when 3389
              service = "RDP"
            when 5000
              service = "UPNP"
            when 5900,5901
              service = "VNC"
            when 6379,6380
              service = "REDIS"
            when 6443
              service = "KUBERNETES"
            when 7001
              service = "WEBLOGIC"
            when 8032
              service = "YARN"
            when 8278,8291
              service = "MIKROTIK"
            when 8883
              service = "MQTT"
            when 9200,9201,9300,9301
              service = "ELASTICSEARCH"
            when 9091,9092,9094
              service = "NETSCALER"
            when 27017,27018,27019
              service = "MONGODB"
            else
              service = "UNKNOWN"
          end

          # now we have all the details we need, create it

          name = "#{h.name}:#{port_num}"

          entity_details = {
            "name" => name,
            "service" => service
          }

          # merge in all generic details
          entity_details = entity_details.merge!(generic_details)

          # merge in any service specifics
          entity_details = entity_details.merge!(service_specific_details)

          sister_entity = _create_entity("NetworkService", entity_details, sister_entity)

        elsif protocol == "udp" && h.name.is_ip_address?

          service_specific_details = {}

          case port_num
            when 53
              service = "DNS"
            when 161
              service = "SNMP"
            when 1900
              service = "UPNP"
            else
              service = "UNKNOWN"
          end

          # now we have all the details we need, create it

          name = "#{h.name}:#{port_num}"

          entity_details = {
            "name" => name,
            "service" => service
          }

          # merge in all generic details
          entity_details = entity_details.merge!(generic_details)

          # merge in any service specifics
          entity_details = entity_details.merge!(service_specific_details)

          sister_entity = _create_entity("NetworkService", entity_details, sister_entity)

        else
          raise "Unknown protocol" if h.name.is_ip_address?
        end
      end # end thread 
    end # each hostname
    thread_list.map(&:join)
  end

  ## Default method, subclasses must override this
  def _masscan_netblock(range,tcp_ports,udp_ports,max_rate=1000)

    ### Santity checking so this function is safe
    unless range.kind_of? Intrigue::Entity::NetBlock
      raise "Invalid range: #{range}"
    end
    unless tcp_ports.all?{|p| p.kind_of? Integer}
      raise "Invalid tcp ports: #{tcp_ports}"
    end
    unless udp_ports.all?{|p| p.kind_of? Integer}
      raise "Invalid udp ports: #{udp_ports}"
    end
    unless max_rate.kind_of? Integer
      raise "Invalid max rate: #{max_rate}"
    end
    ### end santity checking

    begin

      # Create a tempfile to store result
      temp_file = Tempfile.new("masscan")

      port_string = "-p"
      port_string << "#{tcp_ports.join(",")}," if tcp_ports.length > 0
      port_string << "#{udp_ports.map{|x| "U:#{x}" }.join(",")}"

      # shell out to masscan and run the scan
      masscan_string = "masscan #{port_string} --max-rate #{max_rate} -oL #{temp_file.path} --range #{range.name}"
      _log "Running... #{masscan_string}"
      _unsafe_system(masscan_string)

      results = []
      f = File.open(temp_file.path).each_line do |line|

        # Skip comments
        next if line =~ /^#.*/
        next if line.nil?

        # PARSE
        state = line.delete("\n").strip.split(" ")[0]
        protocol = line.delete("\n").strip.split(" ")[1]
        port = line.delete("\n").strip.split(" ")[2].to_i
        ip_address = line.delete("\n").strip.split(" ")[3]

        results << {
          "state" => state,
          "protocol" => protocol,
          "port" => port,
          "ip_address" => ip_address
        }

      end

    ensure
      temp_file.close
      temp_file.unlink
    end

  results
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("masscan") =~ /^usage/
  true
  end


  def _gather_http_response(uri)

    # FIRST CHECK TO SEE IF WE GET A RESPONSE FOR THIS HOSTNAME
    begin

      out = {}
      out[:http_response] = false
      out[:extra_details] = {}

      _log "connecting to #{uri}"

      out[:http_response] = http_request(:get, uri)

      ## TODO ... follow & track location headers?

    rescue ArgumentError => e
      _log_error "Error, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue SocketError => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue Errno::EINVAL => e
      _log_error "Error, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue Errno::EPIPE => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue Errno::ECONNRESET => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue Errno::ECONNREFUSED => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue Errno::EHOSTUNREACH => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue URI::InvalidURIError => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue RestClient::RequestTimeout => e
      _log_error "Timeout requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue RestClient::BadRequest => e
      _log_error "Error requesting resource, skipping: #{uri} #{e}"
      out[:http_response] = false
    rescue RestClient::ResourceNotFound => e
      _log_error "Error (404) requesting resource, creating anyway: #{uri}"
      out[:http_response] = true
    rescue RestClient::MaxRedirectsReached => e
      _log_error "Error (too many redirects) requesting resource, creating anyway: #{uri}"
      out[:http_response] = true
    rescue RestClient::Unauthorized => e
      _log_error "Error (401) requesting resource, creating anyway: #{uri}"
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::Forbidden => e
      _log_error "Error (403) requesting resource, creating anyway: #{uri}"
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::InternalServerError => e
      _log_error "Error (500) requesting resource, creating anyway: #{uri}"
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::BadGateway => e
      _log_error "Error (Bad Gateway) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::ServiceUnavailable => e
      _log_error "Error (Service Unavailable) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::ServerBrokeConnection => e
      _log_error "Error (Server broke connection) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::SSLCertificateNotVerified => e
      _log_error "Error (SSL Certificate Invalid) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue OpenSSL::SSL::SSLError => e
      _log_error "Error (SSL Certificate Invalid) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue Net::HTTPBadResponse => e
      _log_error "Error (Bad HTTP Response) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue RestClient::ExceptionWithResponse => e
      _log_error "Unknown error requesting resource #{uri}, skipping"
      _log_error "#{e}"
    rescue Zlib::GzipFile::Error => e
      _log_error "compression error on #{uri}" => e
    end
  out
  end


end
end
end
