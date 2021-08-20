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
            "fingerprint_sha256" => "b3d1c464976e725e599d3548180cb56311818f224e701f9d56f22e8079a7b396",
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

    not_before = _get_entity_detail("not_before")
    # not before aug 31
    # today aug 20
    if not_before && Time.parse(not_before) > Time.now
      _log "Creating issue for certificate that is not yet valid"
      _create_linked_issue "invalid_certificate_premature", {proof: "Certificate is valid starting from #{not_before}, tested on #{now}"}
    end

    not_after = _get_entity_detail("not_after")
    # not after aug 31
    # today aug 20
    if not_after && Time.parse(not_after) < Time.now
      _log "Creating issue for expired certificate"
      _create_linked_issue "invalid_certificate_expired", {proof: "Certificate has expired on #{not_after}"}
    end

    if _get_entity_detail("issuer") =~ /Let\'s Encrypt/
      almost_expired_time = 604800 # seven days
    else
      almost_expired_time = 2592000 # thirty_days
    end

    ## not afere Aug 31
    ## not afeer - 30 days = July 31
    ## Time.now = Aug 20
    ## Time.now - 30 days = July 20
    if not_after &&
      !(Time.parse(not_after) < Time.now) && # expired
      (Time.parse(not_after) - almost_expired_time) < Time.now # expires in 30 days

      _log "Creating issue for almost expired certificate"
      _create_linked_issue "invalid_certificate_almost_expired", {
        proof: "Not Valid after #{not_after} which is less than the warning window of: #{almost_expired_time/60/60/24} days" }
    end

    # https://www.globalsign.com/en/blog/moving-from-sha-1-to-sha-256
    algo = _get_entity_detail("algorithm")
    invalid_algos = ["MD5", "SHA1"]
    if algo && invalid_algos.include?(algo)
      _log "Creating issue for certificate with invalid algorithm"
      _create_linked_issue "invalid_certificate_algorithm", {
        proof: "Configured Alorigthm is: #{algo}, included in: #{invalid_algos}" }
    end

  end

end
end
end
end