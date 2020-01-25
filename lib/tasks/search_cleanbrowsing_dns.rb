module Intrigue
module Task
class SearchCleanBrowsingDns < BaseTask
  def self.metadata
    {
      :name => "search_cleanbrowsing_dns",
      :pretty_name => "Search CleanBrowsing DNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked by Cleanbrowsing.org DNS",
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
    res = []
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

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

    # We use their DNS servers to query
    nameservers= ['185.228.168.168', '185.228.168.169']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    
    # Try twice, just in case (avoid FP's)
    res = dns_obj.getaddresses(entity_name)
    res.concat(dns_obj.getresources(entity_name, Resolv::DNS::Resource::IN::CNAME)).flatten

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_s}" }}. Seems we're good!"
    else
      source = "CleanBrowsing"
      description = "The Cleanbrowsing DNS security filter focuses on restricting access " + 
        "to malicious activity. It blocks phishing, spam and known malicious domains."
      
      _create_linked_issue("blocked_by_dns", {
        status: "confirmed",
        additional_description: description,
        source: source, 
        proof: "Resolved to the following address(es) outside of #{source} (#{nameservers}): #{resolves_to.join(", ")}",
        to_reproduce: "dig #{entity_name} @#{nameservers.first}",
        references: [{ type: "remediation", uri: "https://cleanbrowsing.org/" }]
      }) 
      
      # Also store it on the entity 
      blocked_list = @entity.get_detail("detected_malicious") || [] 
      @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))

    end

  end

end
end
end
