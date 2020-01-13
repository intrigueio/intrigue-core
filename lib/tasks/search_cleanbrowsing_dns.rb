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
    res2 = dns_obj.getaddresses(entity_name)

    # Detected only if there's no resolution
    if res.any? || res2.any?
      _log "Resolves to #{res.map{|x| "#{x.to_name}" }}  and #{res2.map{|x| "#{x.to_name}" }}. Seems we're good!"
    else
      source = "CleanBrowsing"
      description = "The Cleanbrowsing DNS security filter focuses on restricting access " + 
        "to malicious activity. It blocks phishing, spam and known malicious domains."
      
      _create_linked_issue("blocked_potentially_compromised", {
        status: "confirmed",
        additional_description: description,
        source: source, 
        proof: "Resolved to the following address(es) outside of #{source}: #{resolves_to.join(", ")}",
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
