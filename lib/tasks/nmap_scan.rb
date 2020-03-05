module Intrigue
module Task
class NmapScan < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "nmap_scan",
      :pretty_name => "Nmap Scan",
      :authors => ["jcran"],
      :description => "This task runs an nmap scan on the target host or domain.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["DnsRecord", "Domain", "IpAddress", "NetBlock"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "tcp_ports", :regex => "numeric_list", :default => "21,22,23,80,81,443,445,3389,8000,8009,8080,8081,8443" },
        {:name => "udp_ports", :regex => "numeric_list", :default => "161,500,1900" }
      ],
      :created_types => [ "DnsRecord", "IpAddress", "NetworkService", "Uri" ]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ###
    ### TODO SECURITY - more sanity checking on to_scan
    ###

    # Get range, or host
    to_scan = [_get_entity_name]
    _log "Scan list is: #{to_scan}"

    to_scan.each do |scan_item|

      # Create a tempfile to store results
      temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

      # Check for IPv6
      nmap_options = ""
      nmap_options << "-6" if scan_item =~ /:/

      # construct port list
      port_list = "-p "
      port_list << _get_option("tcp_ports") if _get_option("tcp_ports").split(",").count > 0
      port_list << "," if _get_option("udp_ports").split(",").count > 0
      port_list << _get_option("udp_ports").split(",").map{|p| "U:#{p}" }.join(",")

      # shell out to nmap and run the scan
      _log "Scanning #{scan_item} and storing in #{temp_file}"
      _log "NMap options: #{nmap_options}"

      # shell out to nmap and run the scan
      nmap_string = "nmap #{scan_item} #{nmap_options} -sSUV -P0 -T5 #{port_list}"
      nmap_string << " -O --max-os-tries 2 -oX #{temp_file}"
      nmap_string = "sudo #{nmap_string}" unless Process.uid == 0

      _log "Starting Scan: #{nmap_string}"
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

        # Handle the case of a netblock or domain
        if @entity.type_string == "NetBlock"   ||
           @entity.type_string == "DnsRecord"  ||
           @entity.type_string == "Domain"
          # Only create if we've got ports to report.
          ip_entity = _create_entity("IpAddress", { "name" => host.ip } )
        else
          ip_entity = @entity
        end

        # either way, set os details from nmap
        ip_entity.set_detail("os", host.os.matches)

        # create an array to save all port details for this host
        host_details = []

        # iterate through all open ports
        host.open_ports.each do |port|

          # construct a hash of details for this port
          port_details = nmap_details_for_port(port)

          # create a network service entity
          _create_network_service_entity(
            ip_entity,
            port.number,
            "#{port.protocol}",
            { "nmap" => port_details})

          # save off the port details for later
          host_details << port_details

        end # end ports

        # set the details
        ip_entity.set_detail("nmap", host_details)
        host_details = nil

      end # end parser

      # Clean up!
      parser = nil

      begin
        File.delete(temp_file)
      rescue Errno::EPERM
        _log_error "Unable to delete file"
      end

    end
  end

  def nmap_details_for_port(port)
    {
      "protocol" => "#{port.service.protocol}",
      "ssl" => "#{port.service.ssl?}",
      "product" => "#{port.service.product}",
      "version" => "#{port.service.version}",
      "extra_info" => "#{port.service.extra_info}",
      "hostname" => "#{port.service.hostname}",
      "os_type" => "#{port.service.os_type}",
      "device_type" => "#{port.service.device_type}",
      "fingerprint_method" => "#{port.service.fingerprint_method}",
      "fingerprint" => "#{port.service.fingerprint}",
      "confidence" => "#{port.service.confidence}"
    }
  end

  def check_external_dependencies
    # Check to see if nmap is in the path, and raise an error if not
    return false unless _unsafe_system("sudo nmap") =~ /http:\/\/nmap.org/
  true
  end

end
end
end
