require 'resolv'

module Intrigue
module Task
class SearchQuad9DnS < BaseTask

  def self.metadata
    {
      :name => "search_quad9_dns",
      :pretty_name => "Search Quad9 DNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked by Quad9 DNS (9.9.9.9)",
      :references => ["https://www.quad9.net"],
      :type => "discovery",
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
    res2 = dns_obj.getaddresses(entity_name)

    # Detected only if there's no resolution
    if res.any? || res2.any?
      _log "Resolves to #{res.map{|x| "#{x.to_name}" }}  and #{res2.map{|x| "#{x.to_name}" }}. Seems we're good!"
    else
      source = "Quad9"
      description = "Quad9 routes your DNS queries through a secure network of servers around the " +  
        "globe. The system uses threat intelligence from more than a dozen of the industry’s leading " +
        "cyber security companies to give a real-time perspective on what websites are safe and what " +
        "sites are known to include malware or other threats. If the system detects that the site you " + 
        "want to reach is known to be infected, you’ll automatically be blocked from entry – keeping " +
        "your data and computer safe."

      _create_linked_issue("blocked_potentially_compromised", {
        status: "confirmed",
        additional_description: description,
        source: source, 
        proof: "Resolved to the following address(es) outside of #{source}: #{resolves_to.join(", ")}",
        references:  [{type: "remediation", uri: "https://www.quad9.net/" }]
      })

      # Also store it on the entity 
      blocked_list = @entity.get_detail("detected_malicious") || [] 
      @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))

    end

  end #end run


end
end
end
