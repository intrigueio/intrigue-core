module Intrigue
module Task
class EnrichDomain < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "enrich/domain",
      :pretty_name => "Enrich Domain",
      :authors => ["jcran"],
      :description => "Fills in details for a Domain",
      :references => [],
      :allowed_types => ["Domain"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    lookup_name = _get_entity_name

    # Do a lookup, skip if we already have it (TLD case)
    unless _get_entity_detail("resolutions")

      results = resolve(lookup_name)

      _set_entity_detail("resolutions", collect_resolutions(results) )

      # grab any / all SOA record
      _log "Grabbing SOA"
      soa_details = collect_soa_details(lookup_name)
      _set_entity_detail("soa_record", soa_details)
      check_and_create_domain(soa_details["primary_name_server"]) if soa_details

      # grab any / all MX records (useful to see who accepts mail)
      _log "Grabbing MX"
      mx_records = collect_mx_records(lookup_name)
      _set_entity_detail("mx_records", mx_records)
      mx_records.each{|mx| check_and_create_domain(mx["host"]) }

      # collect TXT records (useful for random things)
      _set_entity_detail("txt_records", collect_txt_records(lookup_name))

      # grab any / all SPF records (useful to see who accepts mail)
      _set_entity_detail("spf_record", collect_spf_details(lookup_name))
    end

    # grab whois info
    out = whois(lookup_name)
    if out
      _set_entity_detail("whois_full_text", out["whois_full_text"])
      _set_entity_detail("nameservers", out["nameservers"])
      _set_entity_detail("contacts", out["contacts"])

      if out["nameservers"]
        out["nameservers"].each do |n|
          check_and_create_domain n
        end
      end
      
    end

  end

end
end
end
