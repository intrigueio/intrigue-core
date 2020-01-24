require 'open-uri'
module Intrigue
module Task
class SearchBlocklistde < BaseTask

  def self.metadata
    {
      :name => "search_blocklistde",
      :pretty_name => "Search Blocklist.de",
      :authors => ["AnasBensalah"],
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
       _create_malicious_ip_issue(entity_name, severity=4)
    end

  end #end run

end
end
end
