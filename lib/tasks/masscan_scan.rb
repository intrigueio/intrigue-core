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
      :type => "discovery",
      :passive => false,
      :allowed_types => ["NetBlock"],
      :example_entities => [{"type" => "NetBlock", "attributes" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [
        {:name => "port", :type => "Integer", :regex => "integer", :default => 80 },
      ],
      :created_types => ["IpAddress", "NetworkService"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get range, or host
    to_scan = _get_entity_name

    unless to_scan =~ /\d.\d.\d.\d/
      _log_error "unsupported scan format"
    end

    opt_port = _get_option("port").to_i

    # Create a tempfile to store result
    temp_file = "#{Dir::tmpdir}/masscan_output_#{rand(10000000000)}.tmp"

    # shell out to masscan and run the scan
    masscan_string = "masscan -p #{opt_port} -oL #{temp_file} #{to_scan}"
    _log "Running... #{masscan_string}"
    _unsafe_system(masscan_string)

    f = File.open(temp_file).each_line do |line|

      # Skip comments
      next if line =~ /^#.*/

      # Get the discovered host (one per line) & create an ip address
      host = line.delete("\n").strip.split(" ")[3] unless line.nil?
      _create_entity("IpAddress", { "name" => host })

      if [80,443,8080,8081,8443].include?(opt_port)
        ssl = true if [443,8443].include?(opt_port)
        protocol = ssl ? "https://" : "http://" # construct uri
        _create_entity("Uri", {"name" => "#{protocol}#{host}", "uri" => "#{protocol}#{host}" })
      else
        _create_entity("NetworkService", {
          "name" => "#{host}:#{opt_port}/tcp",
          "port_num" => opt_port,
          "proto" => "tcp"
        })
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
    return false unless _unsafe_system("masscan") =~ /^usage/
  true
  end

end
end
