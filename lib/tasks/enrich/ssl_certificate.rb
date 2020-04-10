module Intrigue
module Task
module Enrich
class SslCertificate < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/ssl_certificate",
      :pretty_name => "Enrich SSL Certificate",
      :authors => ["jcran"],
      :description => "Fills in details for a SSL Certificate",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["SslCertificate"],
      :example_entities => [
        { "type" => "SslCertificate",
          "details" => {
            "name" => "example.com (1234567890)",
            "serial" => "12345678900",
            "not_before" => "01-01-1999",
            "not_after" => "01-01-2099",
            "subject" => "example",
            "issuer" => "example cert issuer",
            "algorithm" => "SHA256",
            "hidden_text" => "blah blah blah"
          }
        }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    _log "Enriching... SSL Certificate: #{_get_entity_name}"

    if Time.parse(_get_entity_detail("not_before")) > Time.now
      _log "Creating issue for certificate that is not valid yet"
      _create_linked_issue "invalid_certificate_premature"
    end

    if Time.parse(_get_entity_detail("not_after")) < Time.now
      _log "Creating issue for expired certificate"
      _create_linked_issue "invalid_certificate_expired"
    end

    # https://www.globalsign.com/en/blog/moving-from-sha-1-to-sha-256
    if _get_entity_detail("algorithm") == "SHA1" || _get_entity_detail("algorithm") == "MD5" 
      _log "Creating issue for certificate with invalid algorighm"
      _create_linked_issue "invalid_certificate_algorithm"
    end

  end

end
end
end
end