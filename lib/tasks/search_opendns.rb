module Intrigue
module Task
class SearchOpenDns < BaseTask


  def self.metadata
    {
      :name => "search_opendns",
      :pretty_name => "Search OpenDNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked by OpenDNS",
      :references => ["https://www.opendns.com"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["Domain", "DnsRecord"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super
    entity_name = _get_entity_name

    # skip cdns
    if !get_cdn_domains.select{ |x| entity_name =~ /#{x}/}.empty? || 
      !get_internal_domains.select{ |x| entity_name =~ /#{x}/}.empty?
      _log "This domain resolves to a known cdn or internal host, skipping"
      return
    end

    # check that it resolves
    resolves_to = resolve_names entity_name
    unless resolves_to.first
      _log "No resolution for this record, unable to check"
      return
    end

    # Query opendns nameservers
    nameservers = ['208.67.222.222', '208.67.220.220']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    # Try twice, just in case (avoid FP's)
    res = dns_obj.getaddresses(entity_name)
    res.concat(dns_obj.getresources(entity_name, Resolv::DNS::Resource::IN::CNAME)).flatten

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_s}" }}. Seems we're good!"
    else
      source = "OpenDNS"
      description = "OpenDNS (now Cisco Umbrella) provides protection against threats on the internet such as malware, " +
        "phishing, and ransomware."

      _create_linked_issue("blocked_by_dns", {
        status: "confirmed",
        additional_description: description,
        source: source,
        proof: "Resolved to the following address(es) outside of #{source} (#{nameservers}): #{resolves_to.join(", ")}",
        to_reproduce: "dig #{entity_name} @#{nameservers.first}",
        references:
          [{type: "remediation", uri: "https://support.opendns.com/hc/en-us/articles/227987347-Why-is-this-Domain-Blocked-or-not-Blocked-" }]
      })

      # Also store it on the entity
      blocked_list = @entity.get_detail("suspicious_activity_detected") || []
      @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))

    end

  end #end run


end
end
end
