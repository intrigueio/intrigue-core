require 'nmap/parser'

class NmapScanTask < BaseTask

  def metadata
    {
      :name => "nmap_scan",
      :pretty_name => "Nmap Scan",
      :authors => ["jcran"],
      :description => "This task runs an nmap scan on the target host or domain.",
      :references => [],
      :allowed_types => ["DnsRecord", "IpAddress", "NetBlock"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        #{:name => "ports", :type => "String", :regex => "AlphaNumeric", :default => "80" }
      ],
      :created_types => ["IpAddress", "NetSvc", "DnsRecord", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

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
    @task_log.log "Scanning #{to_scan} and storing in #{temp_file}"
    @task_log.log "NMap options: #{nmap_options}"
    nmap_string = "nmap #{to_scan} #{nmap_options} -P0 --top-ports 100 --min-parallelism 10 -oX #{temp_file}"
    @task_log.log "Running... #{nmap_string}"
    _unsafe_system(nmap_string)

    # Gather the XML and parse
    #@task_log.log "Raw Result:\n #{File.open(temp_file).read}"
    @task_log.log "Parsing #{temp_file}"

    parser = ::Nmap::Parser.parsefile(temp_file)

    # Create entities for each discovered service
    parser.hosts("up") do |host|

      @task_log.log "Handling nmap data for #{host.addr}"

      # Handle the case of a netblock or domain - where we will need to create host entity(s)
      if @entity["type"] == "NetBlock" or @entity["type"] == "DnsRecord"
        host_entity = _create_entity("IpAddress", { :name => host.addr } )
      else
        host_entity = @entity # We already have a host
      end

      [:tcp, :udp].each do |proto_type|

        host.getports(proto_type, "open") do |port|

          # Create a NetSvc for each open port
          entity = _create_entity("NetSvc", {
            :name => "#{host.addr}:#{port.num}/#{port.proto}",
            :ip_address => "#{host.addr}",
            :port_num => port.num,
            :proto => port.proto,
            :fingerprint => "#{port.service.name}"})

          # Go ahead and create webapps if this is a known webapp port
          if entity.attributes[:proto] == "tcp" &&
            [80,443,8080,8081,8443].include?(entity.attributes[:port_num])

            # determine if this is an SSL application
            ssl = true if [443,8443].include?(entity.attributes[:port_num])
            protocol = ssl ? "https://" : "http://" # construct uri
            uri = "#{protocol}#{host.addr}:#{entity.attributes[:port_num]}"
            _create_entity("Uri", :name => uri, :uri => uri  ) # create an entity

            # and create the entities if we have dns
            host.hostnames.each do |hostname|
              uri = "#{protocol}#{hostname}:#{entity.attributes[:port_num]}"
              _create_entity("Uri", :name => uri )
            end

          end # end if

        end # end host.getports
      end # end tcp/udp
    end # end parser

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      @task_log.error "Unable to delete file"
    end
  end

  def check_external_dependencies
    # Check to see if nmap is in the path, and raise an error if not
    return false unless _unsafe_system("sudo nmap") =~ /http:\/\/nmap.org/
  true
  end

end
