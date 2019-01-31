require 'thread'
module Intrigue
module Task
class TcpBindAndCollect < BaseTask

  include  Intrigue::Task::Server::Listeners

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
        {:name => "ports", :regex=> "alpha_numeric", :default => "23,25,53,80,81,110,111,443,5000,7001,8000,8001,8008,8081,8080,8443,10000,10001"},
        {:name => "notify", :regex=> "boolean", :default => true },
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

    if _get_option "create_entity"

      source_address = "#{c["source_address"]}"

      # look up the details in team cymru's whois
      whois_details = Intrigue::Client::Search::Cymru::IPAddress.new.whois(source_address)

      # create an entity for the IP
      e = _create_entity("IpAddress",{
        "name" => source_address,
        "asn" => whois_details.first,
        "certificate" => "#{c["source_certificate"]}"
      })

      # create an ASN
      _create_entity("AutonomousSystem", {
        "name" => "AS#{whois_details.first}",
        "cymru" => whois_details
      })

      # create an info for the message (maybe custom type later)
      msg = _create_entity("Info",{
        "name" => "#{Digest::SHA1.hexdigest(c["message"])}",
        "request" => "#{c["message"]}"
      })

      requests = msg.get_detail("requests") || []
      requests << {
        "source_address" => [source_address],
        "source_port" => c["source_port"],
        "source_certificate" => "#{c["source_certificate"]}",
        "dest_port" => c["listening_port"]
      }
      msg.set_detail("requests",requests)
    end

    if _get_option "notify"
      _notify "#{c["source_address"]}:#{c["source_port"]} -> #{c["listening_port"]} ```#{c["message"]}```"
    end
  end

  def bind_and_listen(ports=[])

    if ports.empty?
      ports = [23,25,53,80,81,110,111,443,5000,7001,8000,8001,8008,8081,8080,8443,10000,10001]
    end

    # Create threads to listen to each port
    threads = ports.map do |port|
      _log_good "Creating Background thread to listen for port #{port}"
      Thread.new do

        # if ssl server
        if port =~ /443$/ || port == "22"

          _log_good "Establishing SSL-Enabled Listener for port #{port}"
          start_ssl_listener(port) do |c|
            connection_details = {}
            connection_details["timestamp"] = DateTime.now
            connection_details["listening_address"] = "#{c.addr.last}"
            connection_details["listening_port"] = "#{c.addr[1]}"
            connection_details["source_certificate"] = OpenSSL::X509::Certificate.new(c.peer_cert) if c.peer_cert
            connection_details["source_address"] = "#{c.peeraddr.last}"
            connection_details["source_port"] = "#{c.peeraddr[1]}"
            connection_details["message"] = ""

            readfds = true
            message = []
            begin
              readfds, writefds, exceptfds = select([c], nil, nil, 0.1)
              _log :r => readfds, :w => writefds, :e => exceptfds
              message << c.gets if readfds
            end while readfds
            connection_details["message"] = message.compact.join("")

            track_connection connection_details
            c.close
          end
        else
          # if normal
          _log_good "Establishing TCP Listener for port #{port}"
          start_tcp_listener(port) do |c|
            connection_details = {}
            connection_details["timestamp"] = DateTime.now
            connection_details["listening_address"] = "#{c.addr.last}"
            connection_details["listening_port"] = "#{c.addr[1]}"
            connection_details["source_address"] = "#{c.peeraddr.last}"
            connection_details["source_port"] = "#{c.peeraddr[1]}"
            connection_details["message"] = ""

            readfds = true
            message = []
            begin
              readfds, writefds, exceptfds = select([c], nil, nil, 0.1)
              _log :r => readfds, :w => writefds, :e => exceptfds
              message << c.gets if readfds
            end while readfds
            connection_details["message"] = message.compact.join("")

            track_connection connection_details
            c.close
          end
        end
      end
    end

    # Wait for all threads to complete
    _log "This is a long-running task"
    _log "...waiting until all threads complete to close the task"
    threads.each &:join
  end


end
end
end
