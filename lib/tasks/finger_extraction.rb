###
### XXX - This module has not been extensively tested!
###
module Intrigue
class FingerExtraction < BaseTask

  def self.metadata
    {
      :name => "finger_extraction",
      :pretty_name => "Pull information out of finger",
      :authors => ["jcran"],
      :description => "This task connects to a finger service and pulls out People.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["FingerServer"],
      :example_entities => [
        {"type" => "FingerServer", "attributes" => {
          "ip_address" => "1.1.1.1",
          "port" => 79,
          "protocol" => "tcp"
          }
        }
      ],
      :allowed_options => [ ],
      :created_types => ["Person"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # XXX - how to deal with accepting a complex object like this through
    # the UI? We'd need to know the entity structure, or set these up as options?

    port = _get_entity_attribute("port").to_i || 79
    protocol = _get_entity_attribute "proto"
    ip_address = _get_entity_attribute "ip_address"

    _log "Port: #{port}"
    _log "Protocol: #{protocol}"
    _log "IP Address: #{ip_address}"

    # Check to make sure we have a sane target
    if ip_address && port
      s = TCPSocket.new(ip_address, port)
    else
      raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
    end

    # Probe the port
    begin
      random_string = "#{(0...50).map{ ('a'..'z').to_a[rand(26)]}.join}\n"
      s.puts("bob\n")
      _log(s.read())
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
