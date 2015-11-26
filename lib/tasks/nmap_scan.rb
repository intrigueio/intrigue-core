require 'nmap/program'
require 'nmap/xml'

module Intrigue
class NmapScanTask < BaseTask

  def metadata
    {
      :name => "nmap_scan",
      :pretty_name => "Nmap Scan",
      :authors => ["jcran"],
      :description => "This task runs an nmap scan on the target host or domain.",
      :references => [],
      :allowed_types => ["DnsRecord", "IpAddress", "NetBlock"],
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        #{:name => "ports", :type => "String", :regex => "AlphaNumeric", :default => "80" }
      ],
      :created_types => ["IpAddress", "NetSvc", "DnsRecord", "Uri"]
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
    to_scan = _get_entity_attribute "name"

    # Create a tempfile to store results
    temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

    # Check for IPv6
    nmap_options = ""
    nmap_options << "-6 " if to_scan =~ /:/

    # shell out to nmap and run the scan
    @task_result.logger.log "Scanning #{to_scan} and storing in #{temp_file}"
    @task_result.logger.log "NMap options: #{nmap_options}"
    nmap_string = "nmap #{to_scan} #{nmap_options} -P0 --top-ports 100 --min-parallelism 10 -oX #{temp_file}"
    @task_result.logger.log "Running... #{nmap_string}"
    _unsafe_system(nmap_string)

    # Gather the XML and parse
    #@task_result.logger.log "Raw Result:\n #{File.open(temp_file).read}"
    @task_result.logger.log "Parsing #{temp_file}"

    parser = Nmap::XML.new(temp_file)

    # Create entities for each discovered service
    parser.each_host do |host|
      @task_result.logger.log "Handling nmap data for #{host.ip}"

      # Handle the case of a netblock or domain - where we will need to create host entity(s)
      if @entity.type_string == "NetBlock" or @entity.type_string == "DnsRecord"
        host_entity = _create_entity("IpAddress", { "name" => host.ip } )
      else
        host_entity = @entity # We already have a host
      end

      host.each_port do |port|

        if port.state == :open

          # Create a NetSvc for each open port
          entity = _create_entity("NetSvc", {
            "name" => "#{host.ip}:#{port.number}/#{port.protocol}",
            "ip_address" => "#{host.ip}",
            "port_num" => "#{port.number}",
            "proto" => "#{port.protocol}",
            "fingerprint" => "#{port.service}"})

          # Handle WebApps
          if entity.details["proto"] == :tcp &&
            [80,443,8080,8081,8443].include?(entity.details["port_num"])

            # determine if this is an SSL application
            ssl = true if [443,8443].include?(entity.details["port_num"])
            protocol = ssl ? "https://" : "http://" # construct uri

            # Create URI
            uri = "#{protocol}#{host.ip}:#{entity.details["port_num"]}"
            _create_entity("Uri", "name" => uri, "uri" => uri  ) # create an entity

            # and create the entities if we have dns
            host.hostnames.each do |hostname|
              uri = "#{protocol}#{hostname}:#{entity.details["port_num"]}"
              _create_entity("Uri", "name" => uri, "uri" => uri )
            end

          # Handle FtpServer
          elsif [21].include?(entity.details["port_num"])
            uri = "ftp://#{entity.details["ip_address"]}:#{entity.details["port_num"]}"
            _create_entity("FtpServer", {
              "name" => uri,
              "ip_address" => entity.details["ip_address"],
              "port" => 21,
              "uri" => uri  })

          # Handle SshServer
          elsif [22].include?(entity.details["port_num"])
            uri = "ssh://#{entity.details["ip_address"]}:#{entity.details["port_num"]}"
            _create_entity("SshServer", {
              "name" => uri,
              "ip_address" => entity.details["ip_address"],
              "port" => 22,
              "uri" => uri  })

          end # end if
        end # end if port.state == :open
      end # end host.each_port
    end # end parser

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      @task_result.logger.log_error "Unable to delete file"
    end
  end

  def check_external_dependencies
    # Check to see if nmap is in the path, and raise an error if not
    return false unless _unsafe_system("sudo nmap") =~ /http:\/\/nmap.org/
  true
  end

end
end
