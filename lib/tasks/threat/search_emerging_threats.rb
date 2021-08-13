module Intrigue
module Task
class SearchEmergingThreats < BaseTask

  def self.metadata
    {
      :name => "threat/search_emerging_threats",
      :pretty_name => "Threat Check - Search Emerging Threats",
      :authors => ["Anas Ben Salah"],
      :description => "This task search Emerging Threats blacklist for listed IP address",
      :references => ["https://rules.emergingthreats.net/"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super
    # Get the IpAddress
    entity_name = _get_entity_name

    # Get talos Blacklist IP
    data = http_get_body("https://rules.emergingthreats.net/blockrules/compromised-ips.txt")

    if data == nil
      _log_error("Unable to fetch Url !")
      return
    end

    # Create an issue if an IP found in the Emerging Threats Blacklist
    if data.include? entity_name
       source = "emergingthreats.net"
       description = "emerginthreats.net is a well reputed blacklist "
       _create_linked_issue("suspicious_activity_detected", {
         status: "confirmed",
         additional_description: description,
         source: source,
         proof: "This IP was founded related to malicious activities in #{source}",
         references: []
       })

      # Also store it on the entity
       blocked_list = @entity.get_detail("suspicious_activity_detected") || []
       @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))
    end
  end # end run

end #end class
end
end
