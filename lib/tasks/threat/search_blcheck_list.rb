module Intrigue
module Task
class SearchBlcheckList < BaseTask

  def self.metadata
    {
      :name => "threat/blcheck_list",
      :pretty_name => "Threat Check - Search Blcheck List",
      :authors => ["Anas Ben Salah"],
      :description => "This task Test any domain against more then 100 black lists.",
      :references => [],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress","Domain"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    file = File.open "#{$intrigue_basedir}/data/blcheck.json"
    blacklists = JSON.load file

    # Initialisation
    dns_obj = Resolv::DNS.new()
    # Check IP if they are listed in one of 117 blacklists
    if entity_type == "IpAddress"
      inves = entity_name
      check_blcheck inves, dns_obj, blacklists
    elsif entity_type == "Domain"
      # Resolv domin name address
      inves = dns_obj.getaddress(entity_name)
      check_blcheck inves, dns_obj, blacklists
    else
      _log_error "Unsupported entity type"
    end
  end #run

  # Check the BlackLists database for suspicious or malicious IP addresses or domains
  def check_blcheck inves, dns_obj, blacklists
    # Reverse the IP to match the Dbl rules for checks
    revip = inves.to_s.split(/\./).reverse.join(".")
    i = 1
    f = []
    # Perform nslookup vs every bl in the list
    blacklists.each do |data|
      #puts data["dnsbl"]
      query = revip +"."+ data["dnsbl"]
      f = dns_obj.getaddresses(query)
      _log "#{i}/ 122  checks vs #{data["dnsbl"]} ... "
      # Get the source of the blocker

      # Getting multiple addresses results from the nslookup
      f.each do |j|
        # Investigate if the response is similar to 127.0.0. # for confirming the listing
        if j.to_s.include? "127."
          # Create an issue if the IP is blacklisted
          if data["query"] == true
            source = "#{data["reference"]}#{inves}"
          else
            source = data["reference"]
          end
            #_log "creating issue ... #{source}"

          _create_linked_issue("suspicious_activity_detected", {
            status: "confirmed",
            description: "Suspicious activity was detcted on this entity.",
            proof: "This IP was found in the #{data["dnsbl"]} list",
            source: source,
            confidence: data["confidence"]
          })
          # Also store it on the entity
          blocked_list = @entity.get_detail("suspicious_activity_detected") || []
          @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))
        end
      end
      i += 1
    end
  end

end
end
end
