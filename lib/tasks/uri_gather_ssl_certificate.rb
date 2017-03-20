require 'socket'
require 'openssl'

module Intrigue
class UriGatherSslCertTask  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_gather_ssl_certificate",
      :pretty_name => "URI Gather SSL Certificate",
      :authors => ["jcran"],
      :description => "Grab the SSL certificate from an application server",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [
        {:name => "skip_cloudflare", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_distil", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_fastly", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_incapsula", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_jive", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "skip_wpengine", :type => "Boolean", :regex => "boolean", :default => true }
      ],
      :created_types => ["Host","SslCertificate"]
    }
  end

  def run
    super

    opt_skip_cloudflare = _get_option "skip_cloudflare"
    opt_skip_distill = _get_option "skip_distill"
    opt_skip_incapsula = _get_option "skip_incapsula"
    opt_skip_fastly = _get_option "skip_fastly"
    opt_skip_jive = _get_option "skip_jive"
    opt_skip_wpengine = _get_option "skip_wpengine"

    uri = _get_entity_name

    begin
      hostname = URI.parse(uri).host
      port = 443

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

          _log "Got alt_names: #{alt_names.inspect}"

          # Iterate through, looking for trouble
          alt_names.each do |alt_name|
            if alt_name =~ /cloudflare.com$/ && opt_skip_cloudflare
              _log "This is a cloudflare certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /distilnetworks.com$/ && opt_skip_distill
              _log "This is a distil networks certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /incapsula.com$/ && opt_skip_incapsula
              _log "This is an incapsula certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /fastly.net$/ && opt_skip_fastly
              _log "This is a fastly certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /jiveon.com$/ && opt_skip_jive
              _log "This is a jive certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /wpengine.com$/ && opt_skip_wpengine
              _log "This is a wpengine certificate, skipping further entity creation"
              return
            end
          end

          #assuming we made it this far, let's proceed
          alt_names.each do |alt_name|

            # Remove any leading wildcards so we get a sensible domain name
            if alt_name[0..1] == "*."
              alt_name = alt_name[2..-1]
            end

            _create_entity "Host", { "name" => alt_name }
          end

        end
      end

      # Close the sockets
      ssl_client.sysclose
      tcp_client.close

      # Create an SSL Certificate entity
      _create_entity "SslCertificate", {  "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
                                          "serial" => "#{cert.serial}",
                                          "not_before" => "#{cert.not_before}",
                                          "not_after" => "#{cert.not_after}",
                                          "subject" => "#{cert.subject}",
                                          "issuer" => "#{cert.issuer}",
                                          "algorithm" => "#{cert.signature_algorithm}",
                                          "text" => "#{cert.to_text}" }

    rescue SocketError => e
      _log_error "Caught an error: #{e}"
    rescue Errno::ECONNRESET => e
      _log_error "Caught an error: #{e}"
    rescue Errno::EACCES => e
      _log_error "Caught an error: #{e}"
    rescue Errno::ECONNREFUSED => e
      _log_error "Caught an error: #{e}"
    rescue Errno::ETIMEDOUT => e
      _log_error "Caught an error: #{e}"
    rescue URI::InvalidURIError => e
      _log_error "Invalid URI: #{e}"
      # TODO this is probably an issue with an IPv6 URL... need to be adjusted:
      # https://www.ietf.org/rfc/rfc2732.txt
    rescue OpenSSL::SSL::SSLError => e
      _log_error "Caught an error: #{e}"
    rescue RuntimeError => e
      _log_error "Caught an error: #{e}"
    end
  end

end
end
