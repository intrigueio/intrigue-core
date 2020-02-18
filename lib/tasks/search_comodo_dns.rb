module Intrigue
module Task
class SearchComodoDns < BaseTask


  def self.metadata
    {
      :name => "search_comodo_dns",
      :pretty_name => "Search Comodo DNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked byCleanbrowsing.org DNS (8.26.56.26 and 8.20.247.20)",
      :references => ["Cleanbrowsing.org"],
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

    # Query comodo nameservers
    nameservers = ['8.26.56.26', '8.20.247.20']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    
    # Try twice, just in case (avoid FP's)
    res = dns_obj.getaddresses(entity_name)
    res.concat(dns_obj.getresources(entity_name, Resolv::DNS::Resource::IN::CNAME)).flatten

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_s}" }}. Seems we're good!"
    else
      source = "Comodo"
      description = "Comodo Secure DNS is a domain name resolution service that resolves "  + 
        "DNS requests through our worldwide network of redundant DNS servers, bringing you " + 
        "the most reliable fully redundant DNS service anywhere, for a safer, smarter and" 
        "faster Internet experience."
      
      _create_linked_issue("blocked_by_dns", {
        status: "confirmed",
        additional_description: description,
        source: source, 
        proof: "Resolved to the following address(es) outside of #{source} (#{nameservers}): #{resolves_to.join(", ")}",
        to_reproduce: "dig #{entity_name} @#{nameservers.first}",
        references: [{type: "remediation", uri: "https://www.comodo.com/secure-dns/" }]
      })

      # Also store it on the entity 
      blocked_list = @entity.get_detail("suspicious_activity_detected") || [] 
      @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))

    end
    
  end #end run


end
end
end
