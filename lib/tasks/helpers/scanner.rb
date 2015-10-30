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

  # Scans for webservers on common ports
  #
  # @param [String] ip/hostname/netblock passed to nmap
  # @yield  [uri| invokes a block with a uri for each result
  #
  # @return [Array] list of strings (uris)
  #
  def scan_webservers(to_scan)

    # Create a tempfile to store results
    temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

    # Check for IPv6
    nmap_options = ""
    nmap_options << "-6 " if to_scan =~ /:/

    ports = "80,443,8080,8081,8443"

    # shell out to nmap and run the scan
    @task_result.log "Scanning #{to_scan} and storing in #{temp_file}" if @task_result
    @task_result.log "nmap options: #{nmap_options}" if @task_result
    nmap_string = "nmap #{to_scan} #{nmap_options} -P0 -p #{ports} --min-parallelism 10 -oX #{temp_file}"
    @task_result.log "Running... #{nmap_string}" if @task_result
    _unsafe_system(nmap_string)

    # Gather the XML and parse
    @task_result.log "Parsing #{temp_file}" if @task_result

    parser = ::Nmap::Parser.parsefile(temp_file)

    uris = []

    # Create entities for each discovered service
    parser.hosts("up") do |host|

      @task_result.log "Handling nmap data for #{host.addr}" if @task_result

      [:tcp].each do |proto_type|

        host.getports(proto_type, "open") do |port|

          if proto_type == :tcp && ports.split(",").include?("#{port.num}")

            # determine if this is an SSL application
            ssl = true if [443,8443].include?(port.num)
            protocol = ssl ? "https://" : "http://" # construct uri

            # Create URI
            uris << "#{protocol}#{host.addr}:#{port.num}"

            # and create the entities if we have dns
            host.hostnames.each do |hostname|
              uris<< "#{protocol}#{hostname}:#{port.num}"
            end

          end

        end # end host.getports
      end # end tcp/udp
    end # end parser

    # Here's where we can process the options
    uris.each do |uri|
      yield uri if block_given?
    end

    # Clean up!
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      @task_result.log_error "Unable to delete file"
    end
  uris
  end


end
end
end
