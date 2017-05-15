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
      :allowed_types => ["DnsRecord","IpAddress","NetBlock"],
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","DnsServer","FingerServer", "FtpServer",
        "IpAddress", "NetworkService","SshServer","Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ###
    ### SECURITY - sanity check to_scan
    ###

    # Get range, or host
    to_scan = [_get_entity_name]

    _log "Scan list is: #{to_scan}"

    to_scan.each do |scan_item|

      ### SECURITY!
      #raise "INVALID INPUT: #{scan_item}" unless match_regex :ip_address, scan_item

      # Create a tempfile to store results
      temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

      # Check for IPv6
      nmap_options = ""
      nmap_options << "-6" if scan_item =~ /:/

      # shell out to nmap and run the scan
      _log "Scanning #{scan_item} and storing in #{temp_file}"
      _log "NMap options: #{nmap_options}"

      nmap_string = "nmap #{scan_item} #{nmap_options} -sSUV --top-ports 100 --traceroute -O --max-os-tries 2 -oX #{temp_file}"
      _log "Running... #{nmap_string}"

      output = _unsafe_system(nmap_string)
      _log "Nmap Output:\n#{output}"

      # Gather the XML and parse
      _log "Parsing #{temp_file}"

      parser = Nmap::XML.new(temp_file)

      # Create entities for each discovered service
      parser.each_host do |host|
        _log "Handling nmap data for #{host.ip}"
        _log "Total ports: #{host.ports.count}"
        _log "Total open ports: #{host.each_port.select{|p| p.state == :open}.count}"

        # Handle the case of a netblock or domain - where we will need to create host entity(s)
        if @entity.type_string == "NetBlock"
          # Only create if we've got ports to report.
          ip_entity = _create_entity("IpAddress", { "name" => host.ip } ) if host.ports.count > 0
        else
          ip_entity = @entity
        end

        ip_entity.set_detail("os", host.os.matches)
        ip_entity.set_detail("ports", host.each_port.select{|p| p.state == :open}.map{ |p|
                                    { :state => p.state,
                                      :number => p.number,
                                      :protocol => p.protocol,
                                      :service => {
                                        :protocol => p.service.protocol,
                                        :ssl => p.service.ssl?,
                                        :product => p.service.product,
                                        :version => p.service.version,
                                        :extra_info => p.service.extra_info,
                                        :hostname => p.service.hostname,
                                        :os_type => p.service.os_type,
                                        :device_type => p.service.device_type,
                                        :fingerprint_method => p.service.fingerprint_method,
                                        :fingerprint => p.service.fingerprint,
                                        :confidence => p.service.confidence
                                      }}})

        host.each_port do |port|
          if port.state == :open

            # Handle WebApps first
            if port.protocol == :tcp &&
              [80,443,8080,8081,8443].include?(port.number)

              # determine if this is an SSL application
              ssl = true if [443,8443].include?(port.number)
              protocol = ssl ? "https://" : "http://" # construct uri

              # Create URI
              # and create the entities if we have dns resolution
              uri = "#{protocol}#{host.ip}:#{port.number}"
              _create_entity("Uri", "name" => uri, "uri" => uri  )

              ip_entity.get_aliases("DnsRecord").each do |dns_record_entity|
                next unless dns_record_entity
                uri = "#{protocol}#{dns_record_entity.name}:#{port.number}"
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
