require 'socket'
require 'openssl'
module Intrigue
class UriGatherSslCertTask  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_gather_ssl_certificate",
      :pretty_name => "URI Gather SSL Certificate",
      :authors => ["jcran"],
      :description => "Grab the SSL certificate from an application server",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [
        {:name => "skip_cloudflare", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_distil", :type => "Boolean", :regex => "boolean", :default => true }
      ],
      :created_types => ["DnsRecord","SslCertificate"]
    }
  end

  def run
    super

    opt_allow_cloudflare = _get_option "skip_cloudflare"

    uri = _get_entity_attribute "name"
    hostname = URI.parse(uri).host
    port = 443

    begin
      # Create a socket and connect
      tcp_client = TCPSocket.new hostname, port
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

            if alt_name =~ /cloudflare.com$/
              @task_result.logger.log "This is a cloudflare certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /distilnetworks.com$/
              @task_result.logger.log "This is a distil networks certificate, skipping further entity creation"
              return
            end

            _create_entity "DnsRecord", { "name" => alt_name }
          end

        end
      end

      # Close the sockets
      ssl_client.sysclose
      tcp_client.close

      # Create an SSL Certificate entity
      _create_entity "SslCertificate", {  "name" => "#{cert.subject}",
                                          "text" => "#{cert.to_text}" }

    rescue OpenSSL::SSL::SSLError => e
      @task_result.logger.log_error "Caught an error: #{e}"
    rescue Errno::ECONNRESET => e
      @task_result.logger.log_error "Caught an error: #{e}"
    rescue Errno::EACCES => e
      @task_result.logger.log_error "Caught an error: #{e}"
    rescue Errno::ECONNREFUSED => e
      @task_result.logger.log_error "Caught an error: #{e}"
    rescue RuntimeError => e
      @task_result.logger.log_error "Caught an error: #{e}"
    end
  end

end
end
