require 'net/ftp'

###
### XXX - This module has not been extensively tested!
###
module Intrigue
module Task
class FtpEnumerate < BaseTask

  def self.metadata
    {
      :name => "ftp_enumerate",
      :pretty_name => "Enumerate an FTP server",
      :authors => ["jcran"],
      :description => "This task connects to an FTP service and collects information.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["FtpService","NetworkService"],
      :example_entities => [
        {"type" => "FtpService", "details" => {
          "ip_address" => "1.1.1.1",
          "port" => 1111,
          "protocol" => "tcp"
          }
        }
      ],
      :allowed_options => [
        #{:name => "port_num", :regex => "integer", :default => 111 }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # TODO this won't work once we fix the name regex
    port = _get_entity_detail("port").to_i
    port = 21 if port == 0 # handle empty port
    protocol = _get_entity_detail("protocol") ||  "tcp"
    ip_address = _get_entity_detail("ip_address") || _get_entity_name

    # Check to make sure we have a sane target
    if protocol.downcase == "tcp" && ip_address && port

      begin

        ftp = Net::FTP.new
        ftp.connect(ip_address, port)
        ftp.passive = true

        out = {}
        begin
          _log "attempting anonymous login"
          out["anonymous"] = ftp.login
        rescue Net::FTPPermError => e
          _log_error "unable to log in, proceeding"
        rescue EOFError => e
          _log_error "eof reached"
        end

        begin
          _log "checking HELP command"
          out["help"] = "#{ftp.help}"
        rescue Net::FTPPermError => e
          _log_error "unable to run HELP, proceeding"
        rescue EOFError => e
          _log_error "eof reached"
        end

        begin
          _log "checking permissions"
          ftp.chdir('/')
          out["dir"] = [
            "root" => {
              "listing" => ftp.list,
              "facts" => ftp.mlst.facts
            }
          ]
        rescue Net::FTPPermError => e
          _log_error "unable to collect directory info, not logged in"
        rescue EOFError => e
          _log_error "eof reached"
        end

        begin
          _log "checking SYSTEM command"
          out["system"] = "#{ftp.system}"
        rescue Net::FTPPermError => e
          _log_error "unable to collect system info - not logged in"
        rescue EOFError => e
          _log_error "eof reached"
        end

        _set_entity_detail("ftp_enumerate", out)
        _log out

      rescue SocketError => e
        _log_error "Unable to connect: #{e}"
      rescue Net::FTPPermError=> e
        _log_error "Unable to connect: #{e}"
      rescue Net::FTPTempError => e
        _log_error "Unable to connect: #{e}"
      rescue Errno::ECONNREFUSED => e
        _log_error "Unable to connect: #{e}"
      rescue Errno::ETIMEDOUT => e
        _log_error "Unable to connect: #{e}"
      rescue Errno::ECONNRESET => e
        _log_error "Unable to connect: #{e}"
      rescue Net::ReadTimeout => e
        _log_error "Timeout: #{e}"
      end

    end

  end

end
end
end
