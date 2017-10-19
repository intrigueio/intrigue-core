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
        _create_entity("IpAddress", { "name" => line })

        # Resolve, and iterate on each line
        hostnames = resolve_names(line)
        hostnames.each do |host|

          next if host =~ /\.arpa$/

          # Should we try to resolve first, and fall back on IP?
          #_create_entity("DnsRecord", { "name" => host }) < this should be handled by enrichment...

          if [80,443,8080,8081,8443].include?(opt_port)
            ssl = true if [443,8443].include?(opt_port)
            protocol = ssl ? "https://" : "http://" # construct uri
            _create_entity("Uri", {"name" => "#{protocol}#{host}:#{opt_port}", "uri" => "#{protocol}#{host}:#{opt_port}" })

          elsif opt_port == 21
            uri = "ftp://#{host.ip}:#{opt_port}"
            _create_entity("FtpServer", {
              "name" => "#{host}:#{opt_port}",
              "ip_address" => "#{host}",
              "port" => opt_port,
              "proto" => "tcp",
              "uri" => uri  })

          end
        end
        ### End Resolution

        # Always create the network service
        _create_entity("NetworkService", {
          "name" => "#{line}:#{opt_port}/tcp",
          "ip_address" => "#{line}",
          "port" => opt_port,
          "proto" => "tcp"
        })

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
