###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
class MasscanTask < BaseTask

  def metadata
    {
      :name => "masscan_scan",
      :pretty_name => "Masscan Scan",
      :authors => ["jcran"],
      :description => "This task runs a masscan scan on the target host or domain.",
      :references => [],
      :allowed_types => ["IpAddress", "NetBlock"],
      :example_entities => [{:type => "NetBlock", :attributes => {:name => "10.0.0.0/24"}}],
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
    temp_file = "#{Dir::tmpdir}/masscan_output_#{rand(100000000)}.tmp"

    # shell out to masscan and run the scan
    @task_log.log "Scanning #{to_scan} and storing in #{temp_file}"
    masscan_string = "sudo masscan -p #{port_num} -oL #{temp_file} #{to_scan}"
    @task_log.log "Running... #{masscan_string}"
    _unsafe_system(masscan_string)

    f = File.open(temp_file).each_line do |line|

      next if line =~ /^#.*/

      # Get the discovered host (one per line)
      host = line.delete("\n").strip.split(" ")[3] unless line.nil?

      # Create entity for each discovered host + service
      _create_entity("IpAddress", {:name => host })

      _create_entity("NetSvc", {
        :name => "#{host}:#{port_num}/tcp",
        :port_num => port_num,
        :proto => "tcp"
      })

      _create_entity("Uri", {:name => "http://#{host}", :uri => "http://#{host}" })
    end

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      @task_log.error "Unable to delete file"
    end
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("sudo masscan") =~ /^usage/
  true
  end

end
end
