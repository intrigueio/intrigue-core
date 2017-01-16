###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
class MongoDiscoverTask < BaseTask

  def self.metadata
    {
      :name => "mongo_discover",
      :pretty_name => "Mongo Discover",
      :authors => ["jcran"],
      :description => "This task runs a discovery scan for mongo servers and pulls data",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["IpAddress","NetBlock"],
      :example_entities => [{"type" => "NetBlock", "attributes" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [],
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

    port = 27017

    # Create a tempfile to store result
    temp_file = "#{Dir::tmpdir}/masscan_output_#{rand(10000000000)}.tmp"

    # shell out to masscan and run the scan
    masscan_string = "masscan -p #{port} -oL #{temp_file} #{to_scan}"
    _log "Running... #{masscan_string}"
    _unsafe_system(masscan_string)

    f = File.open(temp_file).each_line do |line|

      # Skip comments
      next if line =~ /^#.*/

      # Get the discovered host (one per line) & create an ip address
      host = line.delete("\n").strip.split(" ")[3] unless line.nil?
      _create_entity "IpAddress", { "name" => host }

      if [27017].include?(port)
        _create_entity("MongoService", {
          "name" => "#{host}:#{port}/tcp",
          "port_num" => port,
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
