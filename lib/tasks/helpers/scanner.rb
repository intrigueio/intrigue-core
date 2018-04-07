###
### Please note - these methods may be used inside task modules, or inside libraries within
### Intrigue. An attempt has been made to make them abstract enough to use anywhere inside the
### application, but they are primarily designed as helpers for tasks. This is why you'll see
### references to @task_result in these methods. We do need to check to make sure it's available before
### writing to it.
###

# This module exists for common web functionality
module Intrigue
module Task
module Scanner

  ## Default method, subclasses must override this
  def _masscan_netblock(range,tcp_ports,udp_ports,max_rate=10000)

    ### Santity checking so this function is safe
    unless range.kind_of? Intrigue::Entity::NetBlock
      raise "Invalid range: #{range}"
    end
    unless tcp_ports.all?{|p| p.kind_of? Integer}
      raise "Invalid tcp ports: #{tcp_ports}"
    end
    unless udp_ports.all?{|p| p.kind_of? Integer}
      raise "Invalid udp ports: #{udp_ports}"
    end
    unless max_rate.kind_of? Integer
      raise "Invalid max rate: #{max_rate}"
    end
    ### end santity checking

    begin

      # Create a tempfile to store result
      temp_file = Tempfile.new("masscan")

      port_string = "-p"
      port_string << "#{tcp_ports.join(",")}," if tcp_ports.length > 0
      port_string << "#{udp_ports.map{|x| "U:#{x}" }.join(",")}"

      # shell out to masscan and run the scan
      masscan_string = "masscan #{port_string} --max-rate #{max_rate} -oL #{temp_file.path} --range #{range.name}"
      _log "Running... #{masscan_string}"
      _unsafe_system(masscan_string)

      results = []
      f = File.open(temp_file.path).each_line do |line|

        # Skip comments
        next if line =~ /^#.*/
        next if line.nil?

        # PARSE
        state = line.delete("\n").strip.split(" ")[0]
        protocol = line.delete("\n").strip.split(" ")[1]
        port = line.delete("\n").strip.split(" ")[2].to_i
        ip_address = line.delete("\n").strip.split(" ")[3]

        results << {
          "state" => state,
          "protocol" => protocol,
          "port" => port,
          "ip_address" => ip_address
        }

      end

    ensure
      temp_file.close
      temp_file.unlink
    end

  results
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("masscan") =~ /^usage/
  true
  end


end
end
end
