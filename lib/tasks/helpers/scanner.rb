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
module Scanner

  def _create_network_service_entity(ip_entity,port_num,protocol="tcp",extra_details={})

    # first, save the port details on the ip_entity
    ports = ip_entity.get_detail("ports") || []
    updated_ports = ports.append({"number" => port_num, "protocol" => protocol}).uniq
    ip_entity.set_detail("ports", updated_ports)

    # Ensure we always save our host
    extra_details.merge!("host_id" => ip_entity.id)

    # Grab all the aliases
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

      # Handle Web Apps first
      if (protocol == "tcp" && [80,443,8080,8000,8081,8443].include?(port_num))

        # Determine if this is SSL
        ssl = true if [443,8443].include?(port_num)
        prefix = ssl ? "https://" : "http://" # construct uri

        # construct the uri
        uri = "#{prefix}#{h.name}:#{port_num}"

        # FIRST CHECK TO SEE IF WE GET A RESPONSE FOR THIS HOSTNAME
        begin

          _log "connecting to #{uri}"
          http_response = RestClient::Request.execute({
            :method => :get,
            :url => uri,
            :timeout => 30,
            :open_timeout => 30
          })

          ## TODO ... follow location headers?

        rescue SocketError => e
          _log_error "Error requesting resource, skipping: #{uri}"
        rescue Errno::ECONNRESET => e
          _log_error "Error requesting resource, skipping: #{uri}"
        rescue Errno::ECONNREFUSED => e
          _log_error "Error requesting resource, skipping: #{uri}"
        rescue Errno::EHOSTUNREACH => e
          _log_error "Error requesting resource, skipping: #{uri}"
        rescue RestClient::RequestTimeout => e
          _log_error "Timeout requesting resource, skipping: #{uri}"
        rescue RestClient::BadRequest => e
          _log_error "Error requesting resource, skipping: #{uri}"
        rescue RestClient::ResourceNotFound => e
          _log_error "Error (404) requesting resource, creating anyway: #{uri}"
          http_response = true
        rescue RestClient::MaxRedirectsReached => e
          _log_error "Error (too many redirects) requesting resource, creating anyway: #{uri}"
          http_response = true
        rescue RestClient::Unauthorized => e
          _log_error "Error (401) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::Forbidden => e
          _log_error "Error (403) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::InternalServerError => e
          _log_error "Error (500) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::BadGateway => e
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::ServiceUnavailable => e
          _log_error "Error (503) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::ServerBrokeConnection => e
          _log_error "Error requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::SSLCertificateNotVerified => e
          _log_error "Error (SSL Certificate Invalid) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue OpenSSL::SSL::SSLError => e
          _log_error "Error (SSL Certificate Invalid) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue Net::HTTPBadResponse => e
          _log_error "Error (Bad HTTP Response) requesting resource, creating anyway: #{uri}"
          http_response = true
          extra_details.merge!("http_server_error" => "#{e}" )
        rescue RestClient::ExceptionWithResponse => err
          _log_error "Unknown error requesting resource, skipping: #{uri}"
          _log_error "INVESTIGATE: #{e}"
        end

        unless http_response
          _log_error "Didn't get a response when we reqested one"
          next
        end

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        # Create entity
        sister_entity = _create_entity("Uri", entity_details, sister_entity)

      # then FtpService
      elsif protocol == "tcp" && [21].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "ftp://#{name}"
        entity_details = {
          "name" => name,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)


        sister_entity = _create_entity("FtpService", entity_details, sister_entity)

      # Then SshService
      elsif protocol == "tcp" && [22].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "ssh://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("SshService", entity_details, sister_entity)

      # then SMTPService
      elsif protocol == "tcp" && [25].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "smtp://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("SmtpService", entity_details, sister_entity)

      # then DnsService
      elsif [53].include?(port_num) && h.name.is_ip_address? # could be either tcp or udp

        name = "#{h.name}:#{port_num}"
        uri = "dns://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("DnsService", entity_details, sister_entity)

      # then FingerService
      elsif protocol == "tcp" && [79].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "finger://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("FingerService", entity_details, sister_entity)

      # Then SnmpService
      elsif protocol == "udp" && [161].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "snmp://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("SnmpService", entity_details, sister_entity)

      # then WeblogicService
      elsif protocol == "tcp" && [7001].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "http://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("WeblogicService", entity_details, sister_entity)

      # then MongoService
      elsif protocol == "tcp" && [27017].include?(port_num) && h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "mongo://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("MongoService", entity_details, sister_entity)

      else # Create a generic network service
        next unless h.name.is_ip_address?

        name = "#{h.name}:#{port_num}"
        uri = "netsvc://#{name}"

        entity_details = {
          "name" => uri,
          "uri" => uri,
          "port" => port_num,
          "ip_address" => h.name,
          "protocol" => protocol}.merge!(extra_details)

        sister_entity = _create_entity("NetworkService", entity_details, sister_entity)
      end

    end # hostnames
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


end
end
end
