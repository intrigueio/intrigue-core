require 'resolv'

module Intrigue
module Task
class SearchQuad9Dns < BaseTask

  def self.metadata
    {
      :name => "search_quad9_dns",
      :pretty_name => "Search Quad9 DNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked by Quad9 DNS (9.9.9.9)",
      :references => ["https://www.quad9.net"],
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
    res = []
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
    
    # Query quad9 nameservers
    nameservers = ['9.9.9.9']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    
    # Try twice, just in case (avoid FP's)
    res = dns_obj.getaddresses(entity_name)
    res.concat(dns_obj.getresources(entity_name, Resolv::DNS::Resource::IN::CNAME)).flatten

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_s}" }}. Seems we're good!"
    else
      source = "Quad9"
      description = "Quad9 routes your DNS queries through a secure network of servers around the " +  
        "globe. The system uses threat intelligence from more than a dozen of the industry’s leading " +
        "cyber security companies to give a real-time perspective on what websites are safe and what " +
        "sites are known to include malware or other threats. If the system detects that the site you " + 
        "want to reach is known to be infected, you’ll automatically be blocked from entry – keeping " +
        "your data and computer safe."

      _create_linked_issue("blocked_by_dns", {
        status: "confirmed",
        additional_description: description,
        source: source, 
        proof: "Resolved to the following address(es) outside of #{source} (#{nameservers}): #{resolves_to.join(", ")}",
        to_reproduce: "dig #{entity_name} @#{nameservers.first}",
        references:  [{type: "remediation", uri: "https://www.quad9.net/" }]
      })

      # Also store it on the entity 
      blocked_list = @entity.get_detail("suspicious_activity_detected") || [] 
      @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))

    end

  end #end run


end
end
end
