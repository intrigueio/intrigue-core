###
### XXX - This module has not been extensively tested!
###
module Intrigue
module Task
class FtpBannerGrab < BaseTask

  def self.metadata
    {
      :name => "ftp_banner_grab",
      :pretty_name => "Grab a banner from an FTP Server",
      :authors => ["jcran"],
      :description => "This task connects to an FTP service and collects the banner.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["FtpService"],
      :example_entities => [
        {"type" => "FtpService", "details" => {
          "ip_address" => "1.1.1.1",
          "port" => 1111,
          "protocol" => "tcp"
          }
        }
      ],
      :allowed_options => [
        #{:name => "port_num", :type => "Integer", :regex => "integer", :default => 111 }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    port = _get_entity_attribute("port").to_i
    protocol = _get_entity_attribute "protocol"
    ip_address = _get_entity_attribute "ip_address"

    # Check to make sure we have a sane target
    if protocol.downcase == "tcp" && ip_address && port

      banner = ""

      sockets = Array.new #select() requires an array
      #fill the first index with a socket
      sockets[0] = TCPSocket.open(ip_address, port)
      while true #loop till it breaks

      #listen for a read, timeout 3
      res = select(sockets, nil, nil,3)
        if res != nil  # a nil is a timeout and will break
              #THIS PRINTS NIL FOREVER on a server crash
          banner << sockets[0].gets()
        else
          sockets[0].close
          break
        end
      end


      if banner.length > 0
        _log "Got banner for #{ip_address}:#{port}/#{protocol}: #{banner}"
        _log "updating entity with banner info!"
        @entity.set_detail "banner", banner
      else
        _log "No banner available"
      end

    end

  end

end
end
end
