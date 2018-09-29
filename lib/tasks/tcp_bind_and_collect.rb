require 'thread'
require 'socket'

module Intrigue
module Task
class TcpBindAndCollect < BaseTask

  def self.metadata
    {
      :name => "tcp_bind_and_collect",
      :pretty_name => "TCP Bind And Collect",
      :authors => ["jcran"],
      :description => "Given a set of ports (or all), bind and collect all connections",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["String"],
      :example_entities =>  [{"type" => "String", "details" => {"name" => "default"}}],
      :allowed_options => [
        {:name => "ports", :regex=> "alpha_numeric", :default => "23,80,110,443,5000,7001,8000,8008,8081,8080,8443,10000"},
        {:name => "notify", :regex=> "boolean", :default => false },
        {:name => "create_entity", :regex=> "boolean", :default => true }
      ],
      :created_types => ["String"]
    }
  end

  def run
    super
    bind_and_listen _get_option("ports").split(",")
  end

  def track_connection(c)
    _log "#{c}"
    e = _create_entity("IpAddress",{"name" => c["source_address"]}) if _get_option "create_entity"
    _notify "#{c["source_address"]}:#{c["source_port"]} -> #{c["listening_port"]} ```#{c["message"]}```" if _get_option "notify"
  end

  def bind_and_listen(ports=[])

    if ports.empty?
      ports = [23,80,110,443,5000,7001,8000,8008,8081,8080,8443,10000]
    end

    # Create threads to listen to each port
    threads = ports.map do |port|
      Thread.new do
        begin
          server = TCPServer.new port
          while true do
            c = server.accept    # Wait for a client to connect
            connection = {}
            connection["timestamp"] = DateTime.now
            connection["listening_address"] = "#{c.addr.last}"
            connection["listening_port"] = "#{c.addr[1]}"
            connection["source_address"] = "#{c.peeraddr.last}"
            connection["source_port"] = "#{c.peeraddr[1]}"
            connection["message"] = ""
            c.each_line do |line|
              connection["message"] << line
            end
            c.close
            track_connection connection
          end
        rescue SocketError => e
          _log_error "Unable to bind: #{e}"
        rescue Errno::EADDRINUSE => e
          _log_error "Unable to bind, #{port} in use: #{e}"
        rescue Errno::EMFILE => e
          _log_error "Too many files, or bind failed: #{e}"
        rescue Errno::EACCES => e
          _log_error "Unable to bind: #{e}"
        end
      end
    end

    # Wait for all threads to complete
    threads.map &:join
  end


end
end
end
