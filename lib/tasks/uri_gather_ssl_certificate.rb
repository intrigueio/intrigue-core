module Intrigue
module Task
class UriGatherSslCert  < BaseTask

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
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [
        {:name => "parse_entities", :regex => "boolean", :default => true },
        {:name => "opt_skip_hosted_services", :regex => "boolean", :default => true },
      ],
      :created_types => ["DnsRecord","SslCertificate"]
    }
  end

  def run
    super

    opt_parse = _get_option "parse_entities"
    opt_skip_hosted_services = _get_option "skip_hosted_services"
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
        if "#{ext.oid}" =~ /subjectAltName/
          alt_names = ext.value.split(",").collect do |x|
            "#{x}".gsub(/DNS:/,"").strip
          end
          _log "Got alt_names: #{alt_names.inspect}"

          tlds = []

          # Iterate through, looking for trouble
          alt_names.each do |alt_name|

            # collect all top-level domains
            tlds << alt_name.split(".").last(2).join(".")

            if (alt_name =~ /acquia-sites.com$/ ) && opt_skip_hosted_services
              _log "This is a cloudflare certificate, skipping further entity creation"
              return
            end

            if (alt_name =~ /cloudflare.com$/ || alt_name =~ /cloudflaressl.com$/ ) && opt_skip_hosted_services
              _log "This is a cloudflare certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /distilnetworks.com$/ && opt_skip_hosted_services
              _log "This is a distil networks certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /fastly.net$/ && opt_skip_hosted_services
              _log "This is a fastly certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /freshdesk.com$/ && opt_skip_hosted_services
              _log "This is a freshdesk certificate, skipping further entity creation"
              return
            end


            if alt_name =~ /jiveon.com$/ && opt_skip_hosted_services
              _log "This is a jive certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /incapsula.com$/ && opt_skip_hosted_services
              _log "This is an incapsula certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /lithium.com$/ && opt_skip_hosted_services
              _log "This is an lithium certificate, skipping further entity creation"
              return
            end

            if alt_name =~ /wpengine.com$/ && opt_skip_hosted_services
              _log "This is a wpengine certificate, skipping further entity creation"
              return
            end
          end

          if opt_skip_hosted_services
            # Generically try to find certs that aren't useful to us
            suspicious_count = 80
            # Check to see if we have over suspicious_count top level domains in this cert
            if tlds.uniq.count >= suspicious_count
              # and then check to make sure none of the domains are greate than a quarter
              _log "This looks suspiciously like a third party cert... over #{suspicious_count} unique TLDs: #{tlds.uniq.count}"
              _log "Total Unique Domains: #{alt_names.uniq.count}"

              # count up the tlds & display
              domain_counts = tlds.each_with_object(Hash.new(0)) { |domain,counts| domain[word] += 1 }
              _log "#{domain_counts.inspect}"

              return
            end
          end

          if opt_parse

            #assuming we made it this far, let's proceed
            alt_names.each do |alt_name|

              # Remove any leading wildcards so we get a sensible domain name
              if alt_name[0..1] == "*."
                alt_name = alt_name[2..-1]
              end

              _create_entity "DnsRecord", { "name" => alt_name }
            end

          end

        end
      end

      # Close the sockets
      ssl_client.sysclose
      tcp_client.close

      # Create an SSL Certificate entity
      _create_entity "SslCertificate", {
        "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
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
    rescue Errno::ENETUNREACH => e
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
end
