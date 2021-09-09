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
  
  def get_certificate(hostname, port, timeout=30)
    
    begin 
      # connect
      socket = connect_ssl_socket(hostname,port,timeout)
    rescue OpenSSL::SSL::SSLError, Errno::ECONNRESET
      _log_error 'Unable to connnect to ssl certificate'
    end
    
    return nil unless socket && socket.peer_cert
    # Grab the cert
    cert = OpenSSL::X509::Certificate.new(socket.peer_cert)
    # parse the cert
    socket.sysclose
  cert
  end

  def _create_network_service_entity(ip_entity,port_num,protocol="tcp",generic_details={})

    # first, save the port details on the ip_entity
    ports = ip_entity.get_detail("ports") || []
    updated_ports = ports.append({"number" => port_num, "protocol" => protocol}).uniq
    ip_entity.set_detail("ports", updated_ports)

    weak_tcp_services = [21, 23, 79]  # possibly 25, but STARTTLS support is currently unclear
    weak_udp_services = [60, 1900, 5000]

    # set sssl if we end in 443 or are in our includeed list 
    ssl = true if port_num.to_s =~ /443$/
    ssl = true if [10000].include?(port_num)

    # Ensure we always save our host and key details.
    # note that we might add service specifics to this below
    generic_details.merge!({
      "port" => port_num,
      "ssl" => ssl,
      "protocol" => protocol,
      "ip_address" => ip_entity.name,
      "asn" => ip_entity.get_detail("asn"),
      "net_name" => ip_entity.get_detail("net_name"),
      "net_country_code" => ip_entity.get_detail("net_country_code"),
      "host_id" => ip_entity.id
    })

    # if this is an ssl port, let's get the CNs and create dns records
    cert_entities = []
    if ssl
      # connect, grab the socket and make sure we
      # keep track of these details, and create entitie
      cert = get_certificate(ip_entity.name,port_num)
      
      if cert 
        
        # grabs cert names, if not a universal cert 
        cert_names = parse_names_from_cert(cert)    

        generic_details.merge!({
          "alt_names" => cert_names,
          "cert" => {
            "version" => cert.version,
            "serial" => "#{cert.serial}",
            "not_before" => "#{cert.not_before}",
            "not_after" => "#{cert.not_after}",
            "subject" => "#{cert.subject}",
            "issuer" => "#{cert.issuer}",
            #"key_length" => key_size,
            "signature_algorithm" => "#{cert.signature_algorithm}"
          }
        })

        # For each of the discovered cert names, now create a 
        # DnsRecord, Domain, or IpAddress.
        if cert_names
          cert_names.uniq do |cn|
            cert_entities << create_dns_entity_from_string(cn) 
          end
        end

      end
    end

    # Grab all the aliases, since we'll want to auto-create services on them
    # (VHOSTS use case)
    hosts = [] 
    # add our ip 
    hosts << ip_entity
    
    # add everything we got from the cert
    hosts.concat(cert_entities)
    
    # add in our aliases 
    hosts.concat(ip_entity.aliases)

    # remove out deny list entities, no sense in wasting time on them
    hosts = hosts.select{|x| !x.project.deny_list_entity?(x) } 
    
    create_service_lambda = lambda do |h|
      try_http_ports = scannable_web_ports

      # Handle web app case first
      if (protocol == "tcp" && try_http_ports.include?(port_num))

        # If SSL, use the appropriate prefix
        prefix = ssl ? "https" : "http" # construct uri

        # Construct the uri. We check for ipv6 and add brackets, to be compliant with the RFC
        if "#{h.name.strip}".match(ipv6_regex)
          uri = "#{prefix}://[#{h.name.strip}]:#{port_num}"
        else
          uri = "#{prefix}://#{h.name.strip}:#{port_num}"
        end

        # if we've never seen this before, go ahead and open it to ensure it's 
        # something we want to create (this helps eliminate unusable urls). However, 
        # skip if we have, we want to minimize requests to the services
        if !entity_exists?(ip_entity.project, "Uri", uri)

          r = _gather_http_response(uri)
          http_response = r[:http_response]
          generic_details.merge!(r[:extra_details])

          unless http_response
            _log_error "Didn't get a response when we requested one, moving on"
            next
          end

          entity_details = {
            "name" => uri,
            "uri" => uri,
            "service" => prefix
          }.merge!(generic_details)
  
          # Create entity
          _create_entity("Uri", entity_details)  

        else 
          _log "Skipping Page grab, entity: #{ip_entity.name} already exists"
        end

      # otherwise, create a network service on the IP, either UDP or TCP - fail otherwise
      elsif protocol == "tcp" && h.name.strip.is_ip_address?

        service_specific_details = {}
        service = _map_tcp_port_to_name(port_num)
       
        # now we have all the details we need, create it
        name = "#{h.name.strip}:#{port_num}/#{protocol}"

        entity_details = {
          "name" => name,
          "service" => service
        }

        # merge in all generic details
        entity_details = entity_details.merge!(generic_details)
        # merge in any service specifics
        entity_details = entity_details.merge!(service_specific_details)

        # now we have all the details we need, create it
        _create_entity("NetworkService", entity_details)

        # if its a weak service, file an issue
        if weak_tcp_services.include?(port_num)
          _create_weak_service_issue(h.name.strip, port_num, service, 'tcp')
        end

      elsif protocol == "udp" && h.name.strip.is_ip_address?

        service_specific_details = {}
        service = _map_udp_port_to_name(port_num)

        # now we have all the details we need, create it
        name = "#{h.name.strip}:#{port_num}/#{protocol}"

        entity_details = {
          "name" => name,
          "service" => service
        }

        # merge in all generic details
        entity_details = entity_details.merge!(generic_details)

        # merge in any service specifics
        entity_details = entity_details.merge!(service_specific_details)

        _create_entity("NetworkService", entity_details)

        # if its a weak service, file an issue
        if weak_udp_services.include?(port_num)
          _create_weak_service_issue(name, port_num, service, 'udp')
        end

      else
        raise "Unknown protocol" if h.name.strip.is_ip_address?
      end

    true
    end

    # use a generic threaded iteration method to create them,
    # with the desired number of threads
    thread_count = (hosts.compact.count / 10) + 1 
    _log "Creating service (#{port_num}) on #{hosts.compact.map{|x| x.name }} with #{thread_count} threads."
        
    # Create our queue of work from the checks in brute_list
    input_queue = Queue.new
    hosts.uniq.compact.each do |item|
      input_queue << item
    end
    
    _threaded_iteration(thread_count, input_queue, create_service_lambda)
        
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
        next if line.match(/^#.*/)
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
    return false unless _unsafe_system("masscan").match(/^usage/i)
  true
  end

  def expand_netblock(netblock)
    converted = IPAddr.new(netblock)
    converted.to_range.to_a[1..-1].map(&:to_s)
  rescue IPAddr::InvalidPrefixError
    _log_error 'Invalid NetBlock!'
  end


  def _gather_http_response(uri)

    # FIRST CHECK TO SEE IF WE GET A RESPONSE FOR THIS HOSTNAME
    begin

      out = {}
      out[:http_response] = false
      out[:extra_details] = {}

      _log "connecting to #{uri}"

      out[:http_response] = http_request(:get, uri, nil, {}, nil)

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
    rescue OpenSSL::SSL::SSLError => e
      _log_error "Error (SSL Certificate Invalid) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue Net::HTTPBadResponse => e
      _log_error "Error (Bad HTTP Response) requesting resource #{uri}, creating anyway."
      out[:http_response] = true
      out[:extra_details].merge!("http_server_error" => "#{e}" )
    rescue Zlib::GzipFile::Error => e
      _log_error "compression error on #{uri}" => e
    end
  out
  end

  def _map_tcp_port_to_name(port_num)
    case port_num
    when 1 
      service = "TCPMUX"
    when 7
      service = "ECHO"
    when 9
      service = "DISCARD"
    when 13
      service = "DAYTIME"
    when 19
      service = "CHARGEN"
    when 21
      service = "FTP"
    when 22,2222
      service = "SSH"
    when 23
      service = "TELNET"
    when 25
      service = "SMTP"
    when 37
      service = "TIME"
    when 42
      service = "NAMESERVER"
    when 49
      service = "TACACS"
    when 53
      service = "DNS"
    when 79
      service = "FINGER"
    when 102 
      service = "TSAP"
    when 105
      service = "CCSO"
    when 109 
      service = "POP2"
    when 110
      service = "POP3"
    when 111
      service = "SUNRPC"
    when 113
      service = "IDENT"
    when 135
      service = "DCERPC"
    when 143
      service = "IMAP"
    when 465
      service = "SMTPS"
    when 502,503
      service = "MODBUS"
    when 587
      service = "SMTP" # https://stackoverflow.com/questions/15796530/what-is-the-difference-between-ports-465-and-587
    when 993
      service = "IMAPS"
    when 995
      service = "POP3S"
    when 1883
      service = "MQTT"
    # https://support.cloudflare.com/hc/en-us/articles/200169156-Identifying-network-ports-compatible-with-Cloudflare-s-proxy
    when 2052
      service = "HTTP-CLOUDFLARE"
    when 2053
      service = "HTTPS-CLOUDFLARE"
    when 2082
      service = "HTTP-CLOUDFLARE"
    when 2083
      service = "HTTPS-CLOUDFLARE"
    when 2086
      service = "HTTP-CLOUDFLARE"
    when 2087
      service = "HTTPS-CLOUDFLARE"
    when 2095
      service = "HTTP-CLOUDFLARE"  
    when 2096
      service = "HTTPS-CLOUDFLARE"
    # End cloudflare oddities
    when 2181,2888,3888 
      service = "ZOOKEEPER"
    when 3306
      service = "MYSQL"
    when 3389
      service = "RDP"
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
      service = "MQTT-SSL"
    when 9200,9201,9300,9301
      service = "ELASTICSEARCH"
    when 9091,9092,9094
      service = "NETSCALER"
    when 27017,27018,27019
      service = "MONGODB"
    else
      service = _service_name_for(port_num, "tcp")
    end
  service
  end

  def _map_udp_port_to_name(port_num)
    case port_num
    when 53
      service = "DNS"
    when 69
      service = "TFTP"
    when 123
      service = "NTP"
    when 161
      service = "SNMP"
    when 1900
      service = "UPNP"
    when 5000
      service = "UPNP"
    else
      service = _service_name_for(port_num, "udp")
    end
  service 
  end


end
end
end
