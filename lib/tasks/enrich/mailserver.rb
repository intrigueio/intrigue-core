module Intrigue
  module Task
  module Enrich
  class Mailserver < Intrigue::Task::BaseTask
  
    def self.metadata
      {
        :name => "enrich/mailserver",
        :pretty_name => "Enrich Mailserver",
        :authors => ["jcran"],
        :description => "Enrich a mailserver entity",
        :references => [],
        :allowed_types => ["Mailserver"],
        :type => "enrichment",
        :passive => true,
        :example_entities => [{"type" => "Mailserver", "details" => {"name" => "mx.intrigue.io"}}],
        :allowed_options => [],
        :created_types => []
      }
    end
  
    def run
      super
      _log "Enriching... Nameserver: #{_get_entity_name}"

      # Use intrigue-ident code to request the banner and fingerprint
      _log "Grabbing banner and fingerprinting!"
      ident = Intrigue::Ident::Ident.new
      ident_matches = ident.generate_smtp_request_and_check(_get_entity_name) || {}
      ident_fingerprints = ident_matches["fingerprints"] || []
      _log "Got #{ident_fingerprints.count} fingerprints!"

      # get the request/response we made so we can keep track of redirects
      ident_banner = ident_matches["banner"]

      if ident_fingerprints.count > 0
        ident_fingeprints = add_vulns_by_cpe(ident_fingerprints)
      end

      _set_entity_detail "banner", ident_banner
      _set_entity_detail "fingerprint", ident_fingerprints


    end # end run
  
  end
  end
  end
  end