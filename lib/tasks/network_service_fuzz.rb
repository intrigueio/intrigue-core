###
### XXX - This module has not been extensively tested!
###
module Intrigue
module Task
class NetworkServiceFuzz < BaseTask

  def self.metadata
    {
      :name => "network_service_fuzz",
      :pretty_name => "Fuzz a NetworkService with random data",
      :authors => ["jcran"],
      :description => "This task connects to a service and sends random data.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["NetworkService"],
      :example_entities => [ {"type" => "NetworkService", "details" => { "name" => "1.1.1.1:79/tcp"}} ],
      :allowed_options => [
        #{:name => "port_num", :type => "Integer", :regex => "integer", :default => 111 }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # XXX - how to deal with accepting a complex object like this through
    # the UI? We'd need to know the entity structure, or set these up as options?

    port = _get_entity_detail("port").to_i
    protocol = _get_entity_detail "proto"
    ip_address = _get_entity_detail "ip_address"

    _log "Port: #{port}"
    _log "Protocol: #{protocol}"
    _log "IP Address: #{ip_address}"

    # Check to make sure we have a sane target
    if protocol.downcase == "tcp"
      if ip_address and port
        s = TCPSocket.new(ip_address, port)
      else
        raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
      end
    else
      #raise ArgumentError, "Unknown Protocol. Unable to open a socket."
      s = UDPSocket.new
      s.connect(ip_address,port)
    end

    # Probe the port
    begin
      100.times do
        s.puts "#{(0...50).map{ ('a'..'z').to_a[rand(26)]}.join}\n"
      end
    rescue Errno::EPIPE
      _log "Broken Pipe"
    rescue Errno::ECONNRESET
      _log "Connection Reset"
    end

    # Cleanup
    s.close
  end

end
end
end
