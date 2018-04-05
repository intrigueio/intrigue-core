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
        #{:name => "port_num", :regex => "integer", :default => 111 }
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

      begin

        ftp = Net::FTP.open("#{ip_address}") do |ftp|

          ftp.passive = true

          out = {}
          begin
            out["anonymous"] = ftp.login
          rescue Net::FTPPermError => e
            _log_error "unable to log in, proceeding"
          end

          begin
              out["help"] = "#{ftp.help}"
          rescue Net::FTPPermError => e
            _log_error "unable to run HELP, proceeding"
          end

          begin
            ftp.chdir('/')
            out["dir"] = [
              "root" => {
                "listing" => ftp.list,
                "facts" => ftp.mlst.facts
              }
            ]
          rescue Net::FTPPermError => e
            _log_error "unable to collect directory info, not logged in"
          end

          begin
            out["system"] = "#{ftp.system}"
          rescue Net::FTPPermError => e
            _log_error "unable to collect system info - not logged in"
          end

          @entity.set_detail("ftp_enumerate", out)
          _log out

        end

      rescue SocketError => e
        _log_error "Unable to connect: #{e}"
      rescue Net::FTPPermError=> e
        _log_error "Invalid creds: #{e}"
      rescue Errno::ECONNREFUSED => e
        _log_error "Unable to connect: #{e}"
      rescue Net::ReadTimeout => e
        _log_error "Timeout: #{e}"
      end

    end

  end

end
end
end
