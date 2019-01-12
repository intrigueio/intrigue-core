module Intrigue
module Task
module Enrich
class NetworkService < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/network_service",
      :pretty_name => "Enrich Network Service",
      :authors => ["jcran"],
      :description => "Fills in details for a Network Service",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["NetworkService"],
      :example_entities => [
        { "type" => "NetworkService",
          "details" => {
            "ip_address" => "1.1.1.1",
            "port" => 1111,
            "protocol" => "tcp"
          }
        }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    _log "Enriching... Network Service: #{_get_entity_name}"

    enrich_ftp if _get_entity_detail("service") == "FTP"

  end

  def enrich_ftp
    # TODO this won't work once we fix the name regex
    port = _get_entity_detail("port").to_i
    port = 21 if port == 0 # handle empty port
    protocol = _get_entity_detail("protocol") ||  "tcp"
    ip_address = _get_entity_detail("ip_address") || _get_entity_name

    # Check to make sure we have a sane target
    if protocol.downcase == "tcp" && ip_address && port

      banner = ""
      begin
        sockets = Array.new #select() requires an array
        #fill the first index with a socket
        sockets[0] = TCPSocket.open(ip_address, port)
        iterations = 0
        max_iterations = 100
        while iterations < max_iterations # loop till we hit max iterations
        _log "Reading from socket #{iterations}/#{max_iterations}"
        # listen for a read, timeout 5
        res = select(sockets, nil, nil, 5)
          if res != nil  # a nil is a timeout and will break
            break unless sockets[0]
            banner << "#{sockets[0].gets()}" # WARNING! THIS PRINTS NIL FOREVER on a server crash
          else
            sockets[0].close
            break
          end
          iterations += 1
        end
      rescue Errno::ETIMEDOUT => e
        _log_error "Unable to connect: #{e}"
      rescue Errno::ECONNRESET => e
        _log_error "Unable to connect: #{e}"
      rescue SocketError => e
        _log_error "Unable to connect: #{e}"
      end

      if banner.length > 0
        _log "Got banner for #{ip_address}:#{port}/#{protocol}: #{banner}"
        _log "updating entity with banner info!"
        _set_entity_detail "banner", banner
      else
        _log "No banner available"
      end

    end
  end

end
end
end
end