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
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://www.intrigue.io"}}],
      :allowed_options => [
        {:name => "parse_entities", :regex => "boolean", :default => true },
        {:name => "skip_hosted_services", :regex => "boolean", :default => true },
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
      port = URI.parse(uri).port

      # connect
      socket = connect_ssl_socket(hostname,port,timeout=30)

      return [] unless socket && socket.peer_cert

      # Parse the cert
      cert = OpenSSL::X509::Certificate.new(socket.peer_cert)

      #assuming we made it this far, let's proceed
      #names.each do |name|
      #  _create_entity "DnsRecord", { "name" => name }
      #end

      # Create an SSL Certificate entity
      key_size = "#{cert.public_key.n.num_bytes * 8}" if cert.public_key && cert.public_key.respond_to?(:n)
      certificate_details = {
        "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
        "version" => cert.version,
        "serial" => "#{cert.serial}",
        "not_before" => "#{cert.not_before}",
        "not_after" => "#{cert.not_after}",
        "subject" => "#{cert.subject}",
        "issuer" => "#{cert.issuer}",
        "key_length" => key_size,
        "signature_algorithm" => "#{cert.signature_algorithm}",
        "hidden_text" => "#{cert.to_text}"
      }
      _create_entity "SslCertificate", certificate_details

    # one way to detect self-signed 
    if cert.subject == cert.issuer
      _create_issue({
        name: "Self-signed certificate detected on #{uri}",
        severity: 5,
        type: "self_signed_certificate",
        status: "confirmed",
        description: "This server is configured with a self-signed certificate",
        references: [
          "https://security.stackexchange.com/questions/93162/how-to-know-if-certificate-is-self-signed/162263"
        ],
          details: { certificate: certificate_details }
        })
    end

    rescue SocketError => e
      _log_error "Caught an error: #{e}"
    rescue Errno::ECONNRESET => e
      _log_error "Caught an error: #{e}"
    rescue Errno::EACCES => e
      _log_error "Caught an error: #{e}"
    rescue Errno::ECONNREFUSED => e
      _log_error "Caught an error: #{e}"
    rescue Errno::EHOSTUNREACH => e
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
    end
  end

end
end
end

