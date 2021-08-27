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
        {:name => "tcp_ports", :regex => "alpha_numeric_list", :default => "scannable" },
        {:name => "udp_ports", :regex => "alpha_numeric_list", :default => "scannable" },
        {:name => "send_rate", :regex => "integer", :default => 5000 },
      ],
      :created_types => [ "DnsRecord","IpAddress", "NetworkService", "Uri" ],
      :queue => "task_scan"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get range, or host
    to_scan = _get_entity_name
    opt_udp_ports = _get_option("udp_ports")
    opt_send_rate = _get_option("send_rate")

    # allow us to programmatically set based on what we know how to scan
    opt_udp_ports = scannable_udp_ports.join(",") if opt_udp_ports == "scannable"

    # provide a set of keywords that can be used to scan
    # the
    if _get_option("tcp_ports") == "all"
      opt_tcp_ports = "0-65535"
    elsif "#{_get_option("tcp_ports")}" == "scannable"
      opt_tcp_ports = scannable_tcp_ports.join(",")
    elsif "#{_get_option("tcp_ports")}".length > 0
      opt_tcp_ports = "#{_get_option("tcp_ports")}"
    else
      opt_tcp_ports = scannable_tcp_ports.join(",")
    end


    begin

      # Create a tempfile to store result
      temp_file_path = "#{$intrigue_basedir}/tmp/masscan-#{rand(1000000000)}"

      port_string = ""
      port_string << "#{opt_tcp_ports}" if opt_tcp_ports.length > 0
      port_string << "," if (opt_tcp_ports.length > 0 && opt_udp_ports.length > 0)
      port_string << "#{opt_udp_ports.split(",").map{|p| "U:#{p}" }.join(",")}" if opt_udp_ports.length > 0

      _log "Port string: #{port_string}"

      # shell out to masscan and run the scan
      masscan_string = "masscan --ports #{port_string} --rate #{opt_send_rate} -oL #{temp_file_path} --range #{to_scan}"
      masscan_string = "sudo #{masscan_string}" unless Process.uid == 0

      _log "Running... #{masscan_string}"
      _unsafe_system(masscan_string, 6000)

      f = File.open(temp_file_path).each_line do |line|

        # Skip comments
        next if line =~ /^#.*/
        next if line.nil?

        # PARSE
        output_line = line.delete("\n").strip.split(" ")
        state = output_line[0]
        protocol = output_line[1]
        port = output_line[2].to_i
        ip_address = output_line[3]

        _log "Got #{state} #{protocol} #{port} #{ip_address}"

        # Get the discovered host (one per line) & create an ip address
        ip_entity = _create_entity("IpAddress", {
          "name" => ip_address,
          "whois_full_text" => _get_entity_detail("whois_full_text")
        })

        if state == "open"
          # this will also add teh the port to the ip address
          _create_network_service_entity(ip_entity, port, protocol, {
              "extended_masscan" => masscan_string
          })
        end

      end

    ensure
      File.delete(temp_file_path)
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
