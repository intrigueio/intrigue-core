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
      ident_matches = generate_smtp_request_and_check(_get_entity_name) || {}
      ident_fingerprints = ident_matches["fingerprints"]
      _log "Got #{ident_fingerprints.count} fingerprints!"

      # get the request/response we made so we can keep track of redirects
      ident_banner = ident_matches["banner"]

      if ident_fingerprints.count > 0

        # Make sure the key is set before querying intrigue api
        intrigueio_api_key = _get_task_config "intrigueio_api_key"
        use_api = intrigueio_api_key && intrigueio_api_key.length > 0

        # for ech fingerprint, map vulns 
        ident_fingerprints = ident_fingerprints.map do |fp|

          vulns = []
          if fp["inference"]
            cpe = Intrigue::Vulndb::Cpe.new(fp["cpe"])
            if use_api # get vulns via intrigue API
              _log "Matching vulns for #{fp["cpe"]} via Intrigue API"
              vulns = cpe.query_intrigue_vulndb_api(intrigueio_api_key)
            else
              vulns = cpe.query_local_nvd_json
            end
          else
            _log "Skipping inference on #{fp["cpe"]}"
          end

          fp.merge!({ "vulns" => vulns })
        end

      end

      _set_entity_detail "banner", ident_banner
      _set_entity_detail "fingerprint", ident_fingerprints


    end # end run
  
  end
  end
  end
  end