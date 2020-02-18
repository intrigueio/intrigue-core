require 'open-uri'
module Intrigue
module Task
class SearchBlocklistde < BaseTask

  def self.metadata
    {
      :name => "search_blocklistde",
      :pretty_name => "Search Blocklist.de",
      :authors => ["Anas Ben Salah"],
      :description => "This task checks IPs vs blocklist.de list for maliciousness IPs ",
      :references => [],
      :type => "discovery",
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

    # Get blocklist.de "all" list
    data = open("https://lists.blocklist.de/lists/all.txt").read

    if data == nil
      _log_error("Unable to fetch Url !")
      return
    end

    # Create an issue if an IP found in the blocklist.de list
    if data.include? entity_name
       #_create_malicious_ip_issue(entity_name, severity=4)
       source = "Blocklist.de"
       description = "www.blocklist.de is a free and voluntary service provided by a Fraud/Abuse-specialist" +
        "whose servers are often attacked via SSH-, Mail-Login-, FTP-, Webserver- and other services." +
        "The mission is to report any and all attacks to the respective abuse departments of the infected PCs/servers"

       _create_linked_issue("suspicious_ip", {
         status: "confirmed",
         #description: "This IP was founded related to malicious activities in Blocklist.de",
         additional_description: description,
         source: source,
         proof: "This IP was founded related to malicious activities in #{source}",
         references: []
       })

       # Also store it on the entity
       blocked_list = @entity.get_detail("detected_malicious") || []
       @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))

    end

  end #end run

end
end
end
