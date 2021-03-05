module Intrigue
module Task
class DnsLookupCAA < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_lookup_caa",
      :pretty_name => "DNS CAA Lookup",
      :authors => ["jen140"],
      :description => "Look up the CAA records of the given DNS record.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [ ],
      :created_types => ["tag","host"]
    }
  end

  def run
    super

    domain_name = _get_entity_name

    _log "Running CAA lookup on #{domain_name}"

    res_answer = collect_caa_records domain_name

    # If we got a success to the query.
    if res_answer.count > 0
      _log "CAA found, skipping"
    else 
      _log "No CAA on the domain!"
                _create_linked_issue("dns_caa_missing", {
                  status: "confirmed"})
    end
  end

end
end
end
