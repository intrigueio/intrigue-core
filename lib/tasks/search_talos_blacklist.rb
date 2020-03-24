require 'open-uri'
module Intrigue
module Task
class SearchTalosBlackList < BaseTask

  def self.metadata
    {
      :name => "threat/search_talos_blacklist",
      :pretty_name => "Threat Check - Search Talos BlackList",
      :authors => ["Anas Ben Salah"],
      :description => "This task checks IPs vs Talos IP BlackList for threat data.",
      :references => [],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the IpAddress
    entity_name = _get_entity_name

    # Get talos Blacklist IP
    data = open("https://talosintelligence.com/documents/ip-blacklist").read

    if data == nil
      _log_error("Unable to fetch Url!")
      return
    end

    # Create an issue if an IP found in the Talos IP Blacklist
    if data.include? entity_name

      source = "talosintelligence.com"
       description = "Cisco Talos Intelligence Group is one of the largest commercial threat" +
       " intelligence teams in the world, comprised of world-class researchers, analysts and "
       " engineers. These teams are supported by unrivaled telemetry and sophisticated systems "
       " to create accurate, rapid and actionable threat intelligence for Cisco customers."

       _create_linked_issue("suspicious_activity_detected", {
         status: "confirmed",
         #description: "This IP was found related to malicious activities in Talos Intelligence IP BlackList",
         additional_description: description,
         source: source,
         proof: "This IP was detected as suspicious in #{source}",
         references: []
       })

      # Also store it on the entity
       blocked_list = @entity.get_detail("suspicious_activity_detected") || []
       @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))

    end

  end #end run

end
end
end
