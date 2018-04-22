module Intrigue
module Task
module Generic

  def self.included(base)
     include Intrigue::Task::Web
   end

  private

  ###
  ### Helper method to reach out to the entity manager
  ###
  def _create_entity(type, hash, primary_entity=nil)
    # No need for a name in the hash now, remove it & pull out the name from the hash
    name = hash.delete("name")

    # Create or merge the entity
    EntityManager.create_or_merge_entity(@task_result, type, name, hash, primary_entity)
  end

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
            :timeout => 5,
            :open_timeout => 5
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

  ###
  ### Logging helpers
  ###
  def _log(message)
    @task_result.logger.log message
  end

  def _log_good(message)
    @task_result.logger.log_good message
  end

  def _log_error(message)
    @task_result.logger.log_error message
  end

  # Convenience Method to execute a system command semi-safely
  #  !!!! Don't send anything to this without first whitelisting user input!!!
  def _unsafe_system(command)

    ###                  ###
    ###  XXX - SECURITY  ###
    ###                  ###

    if command =~ /(\||\;|\`)/
      #raise "Illegal character"
      _log_error "FATAL Illegal character in #{command}"
      return
    end

    `#{command}`
  end

  ###
  ### Helpers for handling encoding
  ###

  def _encode_string(string)
    return string unless string.kind_of? String
    string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
  end

  def _encode_hash(hash)
    return hash unless hash.kind_of? Hash
    hash.each {|k,v| hash[k] = _encode_string(v) if v.kind_of? String }
  hash
  end

  ## Helper methods for getting common entity data
  def _get_entity_attribute(attrib_name)
    if attrib_name == "name"
      "#{@task_result.base_entity.name}"
    else
      "#{@task_result.base_entity.get_detail(attrib_name)}"
    end
  end

  def _get_entity_name
    "#{@task_result.base_entity.name}"
  end

  def _get_entity_type_string
    "#{@task_result.base_entity.type}".split(":").last
  end

  ### GLOBAL CONFIG INTERFACE

  def _get_global_config(key)
    begin
      value = Intrigue::Config::GlobalConfig.new.config["intrigue_global_module_config"][key]["value"]
      if value && value != ""
        #_log "Using config #{key} ending in #{value[-3..-1]}"
      else
        _log "API Key (#{key}) is blank or missing. Check the admin tab!"
      end
    rescue NoMethodError => e
      _log "Error, invalid config key requested (#{key}) #{e}"
    end
  value
  end

  ###
  ### XXX TODO - move this up into the setup method and make it happen automatically
  ###
  def _get_option(name)

    # Start with nothing
    value = nil

    # First, get the default value by cycling through the allowed options
    method = self.class.metadata[:allowed_options].each do |allowed_option|
      value = allowed_option[:default] if allowed_option[:name] == name
    end

    # Then, cycle through the user-provided options
    @user_options.each do |user_option|
      value = user_option[name] if user_option.key?(name)
    end

  value
  end


end
end
end
