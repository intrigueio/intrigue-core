require 'socket'
require 'openssl'

class UriGatherMetadataTask  < BaseTask

  include Task::Web

  def metadata
    { 
      :name => "uri_gather_metadata",
      :pretty_name => "URI Gather Metadata",
      :authors => ["jcran"],
      :description => "Grab metadata from a URI",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{:type => "Uri", :attributes => {:name => "http://www.intrigue.io"}}],
      :allowed_options => [], # TODO
      :created_types => ["DnsRecord","SslCertificate"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"
    hostname = URI.parse(uri).host
    port = 443

    ###
    ### TODO - gather all metadata - https://metainspectordemo.herokuapp.com/scrape?url=http%3A%2F%2Fintrigue.io
    ###

    _gather_ssl_cert(hostname,port)
    _gather_headers

  end

  def _gather_headers
    uri = _get_entity_attribute "name"

    response = http_get(uri)

    if response
      response.each_header do |name,value|
        _create_entity("HttpHeader", {
          :name => "#{name}",
          :content => "#{value}" })
      end
    end
  end



  def _gather_ssl_cert(hostname,port)
    begin
      Timeout.timeout(20) do
        # Create a socket and connect
        tcp_client = TCPSocket.new(hostname, port)
        ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client

        # Grab the cert
        ssl_client.connect

        # Parse the cert
        cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)

        # Check the subjectAltName property, and if we have names, here, parse them.
        cert.extensions.each do |ext|
          if ext.oid =~ /subjectAltName/

            alt_names = ext.value.split(",").collect do |x|
              x.gsub(/DNS:/,"").strip
            end

            alt_names.each do |alt_name|
              _create_entity "DnsRecord", { :name => alt_name }
            end

          end
        end

        # Close the sockets
        ssl_client.sysclose
        tcp_client.close

        # Create an SSL Certificate entity
        _create_entity "SslCertificate", {  :name => cert.subject,
          :text => cert.to_text }
        end
      rescue TypeError => e
        @task_log.log "Couldn't connect: #{e}"
      rescue Timeout::Error
        @task_log.log "Timed out"
      rescue SocketError => e
        @task_log.error "Caught an error: #{e}"
      rescue OpenSSL::SSL::SSLError => e
        @task_log.error "Caught an error: #{e}"
      rescue Errno::ECONNRESET => e
        @task_log.error "Caught an error: #{e}"
      rescue Errno::ECONNREFUSED => e
        @task_log.error "Caught an error: #{e}"
      rescue RuntimeError => e
        @task_log.error "Caught an error: #{e}"
      end
    end

end
