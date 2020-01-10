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
    
    # check that it resolves
    unless resolve_name entity_name
      _log "No resolution for this record, unable to check"
      return 
    end
    
    # Query opendns nameservers
    nameservers = ['208.67.222.222', '208.67.220.220']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    res = dns_obj.getaddresses(entity_name)

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_name}" }}. Seems we're good!"
    else
      description = "Cisco Umbrella provides protection against threats on the internet such as malware, " + 
        "phishing, and ransomware."

      _malicious_entity_detected("OpenDNS", description) 
    end

  end #end run


end
end
end
