  module Intrigue
module Task
class UriGatherSslCert  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_gather_ssl_certificate",
      :pretty_name => "URI Gather SSL Certificate",
      :authors => ["jcran","Anas Ben Salah"],
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

      # use helper function to grab certificate details
      certificate_details = get_certificate_details hostname, port

      # return if no details were provided
      return [] unless certificate_details

      # create certificate entity
      _create_entity "SslCertificate", certificate_details

    # one way to detect self-signed
    if certificate_details["subject"] == certificate_details["issuer"]
      _create_linked_issue("self_signed_certificate",{
        proof: "The following site: #{uri} is configured with a self-signed certificate",
        detailed_description: "The following site: #{uri} is configured with a self-signed certificate",
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
