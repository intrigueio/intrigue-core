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

    # Do a lookup and keep track of all aliases
    results = resolve(lookup_name)
    _set_entity_detail("resolutions", collect_resolutions(results) )

        # grab any / all SOA record
    _set_entity_detail("soa_record", collect_soa_details(lookup_name))

    # grab any / all MX records (useful to see who accepts mail)
    _set_entity_detail("mx_records", collect_mx_records(lookup_name))

    # collect TXT records (useful for random things)
    _set_entity_detail("txt_records", collect_txt_records(lookup_name))

    # grab any / all SPF records (useful to see who accepts mail)
    _set_entity_detail("spf_record", collect_spf_details(lookup_name))

    # grab whois info
    out = whois(lookup_name)
    if out
      _set_entity_detail("whois_full_text", out["whois_full_text"])
      _set_entity_detail("nameservers", out["nameservers"])
      _set_entity_detail("contacts", out["contacts"])
    end

  end

end
end
end
