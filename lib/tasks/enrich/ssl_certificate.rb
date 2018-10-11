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
      :allowed_types => ["SSLCertificate"],
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
    _log "Enriching... nework_service #{_get_entity_name}"
  end

end
end
end
end