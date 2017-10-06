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
      :allowed_types => ["FtpServer"],
      :example_entities => [
        {"type" => "FtpServer", "details" => {
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
    protocol = _get_entity_attribute "proto"
    ip_address = _get_entity_attribute "ip_address"

    #_log "Port: #{port}"
    #_log "Protocol: #{protocol}"
    #_log "IP Address: #{ip_address}"

    # Check to make sure we have a sane target
    if protocol.downcase == "tcp"
      if ip_address and port
        s = TCPSocket.new(ip_address, port)
      else
        raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
      end
    end

    # Probe the port
    begin
      banner = s.gets(10000)

      _log "Got banner for #{ip_address}:#{port}/#{protocol}: #{banner}"
      _log "updating entity with banner info!"

      @entity.set_detail "banner", banner

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
