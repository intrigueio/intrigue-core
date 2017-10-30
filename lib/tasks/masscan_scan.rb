###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
module Task
class Masscan < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "masscan_scan",
      :pretty_name => "Masscan Scan",
      :authors => ["jcran"],
      :description => "This task runs a masscan scan on the target host or domain.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["IpAddress","NetBlock"],
      :example_entities => [{"type" => "NetBlock", "details" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [
        {:name => "port", :type => "Integer", :regex => "integer", :default => 80 },
      ],
      :created_types => ["IpAddress","NetworkService"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get range, or host
    ### SECURITY!
    to_scan = _get_entity_name
    raise "INVALID INPUT: #{to_scan}" unless match_regex :ip_address, to_scan

    ### SECURITY!
    opt_port = _get_option("port").to_i
    raise "INVALID INPUT: #{opt_port}" unless match_regex :integer, opt_port

    begin

      # Create a tempfile to store result
      temp_file = Tempfile.new("masscan")

      # shell out to masscan and run the scan
      masscan_string = "masscan -p #{opt_port} -oL #{temp_file.path} #{to_scan}"
      _log "Running... #{masscan_string}"
      _unsafe_system(masscan_string)

      f = File.open(temp_file.path).each_line do |line|

        # Skip comments
        next if line =~ /^#.*/

        # Get the discovered host (one per line) & create an ip address
        line = line.delete("\n").strip.split(" ")[3] unless line.nil?
        e = _create_entity("IpAddress", { "name" => line })

        _create_network_service_entity(e,
            opt_port,
            "tcp",{
              :masscan_details => {
                :masscan_config => masscan_string
              }
            }
         )

      end

    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("masscan") =~ /^usage/
  true
  end

end
end
end
