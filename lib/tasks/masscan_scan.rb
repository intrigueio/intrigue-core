require 'resolv'
###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
class MasscanTask < BaseTask

  def self.metadata
    {
      :name => "masscan_scan",
      :pretty_name => "Masscan Scan",
      :authors => ["jcran"],
      :description => "This task runs a masscan scan on the target host or domain.",
      :references => [],
      :allowed_types => ["NetBlock"],
      :example_entities => [{"type" => "NetBlock", "attributes" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [
        {:name => "port", :type => "Integer", :regex => "integer", :default => 80 },
      ],
      :created_types => ["IpAddress", "NetSvc"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get range, or host
    to_scan = _get_entity_name

    if to_scan =~ /::/
      _log_error "Ipv6 scanning not currently supported"
      return
    end

    opt_port = _get_option "port"

    # Create a tempfile to store result
    temp_file = "#{Dir::tmpdir}/masscan_output_#{rand(100000000)}.tmp"

    # shell out to masscan and run the scan
    _log "Scanning #{to_scan} and storing in #{temp_file}"
    masscan_string = "sudo masscan -p #{opt_port} -oL #{temp_file} #{to_scan}"
    _log "Running... #{masscan_string}"
    _unsafe_system(masscan_string)

    f = File.open(temp_file).each_line do |line|

      # Skip comments
      next if line =~ /^#.*/

      # Get the discovered host (one per line)
      host = line.delete("\n").strip.split(" ")[3] unless line.nil?

      # Create entity for each discovered host + service
      _create_entity("IpAddress", {"name" => host })

      _create_entity("NetSvc", {
        "name" => "#{host}:#{opt_port}/tcp",
        "port_num" => opt_port,
        "proto" => "tcp"
      })

      ### Resolve the IP
      begin
        resolved_name = Resolv.new.getname(host).to_s
      rescue Resolv::ResolvError => e
        # silently lose these for now.
      end

      if resolved_name
        _log_good "Creating domain #{resolved_name}"
        # Create our new dns record entity with the resolved name
        _create_entity("DnsRecord", {"name" => resolved_name})
        _create_entity("Uri", {"name" => "https://#{resolved_name}", "uri" => "https://#{resolved_name}" }) if opt_port == 443
        _create_entity("Uri", {"name" => "http://#{resolved_name}", "uri" => "http://#{resolved_name}" }) if opt_port == 80
      else
        _log "Unable to find a name for #{host}"
        # Create a URI entity if we're on a commonly known port
        _create_entity("Uri", {"name" => "https://#{host}", "uri" => "https://#{host}" }) if opt_port == 443
        _create_entity("Uri", {"name" => "http://#{host}", "uri" => "http://#{host}" }) if opt_port == 80
      end
      ### End Resolution

    end

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      _log_error "Unable to delete file"
    end
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("sudo masscan") =~ /^usage/
  true
  end

end
end
