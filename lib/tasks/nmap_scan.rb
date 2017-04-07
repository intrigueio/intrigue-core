require 'nmap/xml'

module Intrigue
class NmapScanTask < BaseTask

  def self.metadata
    {
      :name => "nmap_scan",
      :pretty_name => "Nmap Scan",
      :authors => ["jcran"],
      :description => "This task runs an nmap scan on the target host or domain.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Host","NetBlock"],
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Host","DnsServer","FingerServer", "FtpServer",
        "NetworkService","SshServer","Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ###
    ### SECURITY - sanity check to_scan
    ###

    # Allow the user to set the port ranges
    #ports = _get_option "ports"

    # Get range, or host
    if @entity.type_string == "NetBlock"
      to_scan = [_get_entity_name]
    else
      to_scan = @entity.details["ip_addresses"].concat @entity.details["dns_records"]
    end

    _log "Scan list is: #{to_scan}"

    to_scan.each do |scan_id|

      ### SECURITY!
      raise "INVALID INPUT: #{scan_id}" unless match_regex :ip_address, scan_id

      # Create a tempfile to store results
      temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

      # Check for IPv6
      nmap_options = ""
      nmap_options << "-6" if scan_id =~ /:/

      # shell out to nmap and run the scan
      _log "Scanning #{scan_id} and storing in #{temp_file}"
      _log "NMap options: #{nmap_options}"

      nmap_string = "nmap #{scan_id} #{nmap_options} -O -P0 --top-ports 100 --min-parallelism 10 -O --max-os-tries 1 -oX #{temp_file}"
      _log "Running... #{nmap_string}"
      _unsafe_system(nmap_string)

      # Gather the XML and parse
      #_log "Raw Result:\n #{File.open(temp_file).read}"
      _log "Parsing #{temp_file}"

      parser = Nmap::XML.new(temp_file)

      # Create entities for each discovered service
      parser.each_host do |host|
        _log "Handling nmap data for #{host.ip}"

        # Handle the case of a netblock or domain - where we will need to create host entity(s)
        if @entity.type_string == "NetBlock" #or @entity.type_string == "Host"
          # Only create if we've got ports to report.
          _create_entity("Host", { "name" => host.ip } ) if host.ports.count > 0
        end

        @entity.lock!
        @entity.update(:details => @entity.details.merge({"os" => host.os.matches}))
        @entity.save

        host.each_port do |port|
          if port.state == :open

            # Handle WebApps first
            if port.protocol == :tcp &&
              [80,443,8080,8081,8443].include?(port.number)

              # determine if this is an SSL application
              ssl = true if [443,8443].include?(port.number)
              protocol = ssl ? "https://" : "http://" # construct uri

              # Create URI
              uri = "#{protocol}#{host.ip}:#{port.number}"
              _create_entity("Uri", "name" => uri, "uri" => uri  ) # create an entity

              # and create the entities if we have dns resolution
              @entity.details["dns_names"].each do |hostname|
                uri = "#{protocol}#{hostname}:#{port.number}"
                _create_entity("Uri", "name" => uri, "uri" => uri )
              end

            # then FtpServer
            elsif [21].include?(port.number)
              uri = "ftp://#{host.ip}:#{port.number}"
              _create_entity("FtpServer", {
                "name" => uri,
                "ip_address" => "#{host.ip}",
                "port" => port.number,
                "proto" => port.protocol,
                "uri" => uri  })

            # Then SshServer
            elsif [22].include?(port.number)
              uri = "ssh://#{host.ip}:#{port.number}"
              _create_entity("SshServer", {
                "name" => uri,
                "ip_address" => "#{host.ip}",
                "port" => port.number,
                "proto" => port.protocol,
                "uri" => uri  })

            # then DnsServer
          elsif [53].include?(port.number)
              uri = "#{host.ip}:#{port.number}"
              _create_entity("DnsServer", {
                "name" => uri,
                "ip_address" => "#{host.ip}",
                "port" => port.number,
                "proto" => port.protocol,
                "uri" => uri  })

            # then FingerServer
            elsif [79].include?(port.number)
              uri = "finger://#{host.ip}:#{port.number}"
              _create_entity("FingerServer", {
                "name" => uri,
                "ip_address" => "#{host.ip}",
                "port" => port.number,
                "proto" => port.protocol,
                "uri" => uri  })

            # Otherwise default to an unknown network service
            else

              _create_entity("NetworkService", {
                "name" => "#{host.ip}:#{port.number}/#{port.protocol}",
                "ip_address" => "#{host.ip}",
                "port" => port.number,
                "proto" => port.protocol,
                "fingerprint" => "#{port.service}"})

            end # end if
          end # end if port.state == :open
        end # end host.each_port
      end # end parser

      # Clean up!
      begin
        File.delete(temp_file)
      rescue Errno::EPERM
        _log_error "Unable to delete file"
      end
    end
  end

  def check_external_dependencies
    # Check to see if nmap is in the path, and raise an error if not
    return false unless _unsafe_system("sudo nmap") =~ /http:\/\/nmap.org/
  true
  end

end
end
