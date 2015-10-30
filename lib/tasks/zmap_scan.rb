###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
class ZmapScanTask < BaseTask

  def metadata
    {
      :name => "zmap_scan",
      :pretty_name => "Zmap Scan",
      :authors => ["jcran"],
      :description => "This task runs a zmap scan on the target host or domain.",
      :references => [],
      :allowed_types => ["NetBlock"],
      :example_entities => [{"type" => "NetBlock", "attributes" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [],
      :created_types => ["IpAddress", "NetSvc"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # XXX CURRENTLY HARDCODED FOR A SINGLE PORT
    port_num = 80

    # Get range, or host
    to_scan = _get_entity_attribute "name"

    # Create a tempfile to store result
    temp_file = "#{Dir::tmpdir}/zmap_output_#{rand(100000000)}.tmp"

    # shell out to nmap and run the scan
    @task_result.log "Scanning #{to_scan} and storing in #{temp_file}"

    zmap_string = "sudo zmap -p #{port_num} -o #{temp_file} #{to_scan}"
    @task_result.log "Running... #{zmap_string}"
    _unsafe_system(zmap_string)

    f = File.open(temp_file).each_line do |host|

      # Get the discovered host (one per line)
      host = host.delete("\n").strip unless host.nil?

      # Create entity for each discovered host + service
      _create_entity("IpAddress", {"name" => host })

      _create_entity("NetSvc", {
        "name" => "#{host}:#{port_num}/tcp",
        "port_num" => port_num,
        "proto" => "tcp"
      })

      _create_entity("Uri", {"name" => "http://#{host}", "uri" => "http://#{host}" })

    end

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      @task_result.log_error "Unable to delete file"
    end
  end

  def check_external_dependencies
    # Check to see if zmap is in the path, and raise an error if not
    unless _unsafe_system("sudo zmap 2>&1") =~ /target port/
      return false
    end
  true
  end

end
end
