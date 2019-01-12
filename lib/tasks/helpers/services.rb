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

  def _create_network_service_entity(ip_entity,port_num,protocol="tcp",generic_details={})

    # first, save the port details on the ip_entity
    ports = ip_entity.get_detail("ports") || []
    updated_ports = ports.append({"number" => port_num, "protocol" => protocol}).uniq
    ip_entity.set_detail("ports", updated_ports)

    # Ensure we always save our host and key details.
    # note that we might add service specifics to this below
    generic_details.merge!({
      "port" => port_num,
      "protocol" => protocol,
      "ip_address" => ip_entity.name,
      "host_id" => ip_entity.id
    })

    # Grab all the aliases, since we'll want to auto-create services on them
    # (VHOSTS use case)
    hosts = [ip_entity]
    if ip_entity.aliases.count > 0
      ip_entity.aliases.each do |a|
        next unless a.type_string == "DnsRecord" #  only dns records
        next if a.hidden # skip hidden
        hosts << a # add to the list
      end
    end
    _log "Creating services on each of: #{hosts.map{|h| h.name } }"

    sister_entity = nil
    hosts.uniq.each do |h|

      # Handle web app case first
      if (protocol == "tcp" && [80,81,443,8080,8000,8081,8443].include?(port_num))

        # Determine if this is SSL
        ssl = true if [443,8443].include?(port_num)
        prefix = ssl ? "https" : "http" # construct uri

        # Construct the uri
        uri = "#{prefix}://#{h.name}:#{port_num}"

        x= _gather_http_response(uri)
        http_response = x[:http_response]
        generic_details.merge!(x[:extra_details])

        unless http_response
          _log_error "Didn't get a response when we requested one, moving on"
          next
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
          when 22
            service = "SSH"
          when 23
            service = "TELNET"
          when 25
            service = "SMTP"
          when 79
            service = "FINGER"
          when 110
            service = "POP3"
          when 111
            service = "SUNRPC"
          when 7001
            service = "WEBLOGIC"
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


    end # each hostname
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
