require "open-uri"
module Intrigue
module Task
class SearchBadIps < BaseTask

  def self.metadata
    {
      :name => "search_badips",
      :pretty_name => "Search Badips.com",
      :authors => ["Anas Ben Salah"],
      :description => "This task search BadIps blacklist for listed IP address",
      :references => ["https://www.badips.com/"],
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

  # Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name

    # Get the Api response
    response = open("https://www.badips.com/get/info/#{entity_name}").read
    result = JSON.parse(response)

    # Check if the IP is listed
    if result["Listed"] == false
      return
    # Create an issue if the ip is flaged in badips.com list
    elsif result["Listed"] == true

      source = "badips.com"
      description = "www.badips.com is an abuse tracker with a simple API to report and consume blocklists."

      # Create an issue if the ip is flaged in one of the blacklists
      _create_linked_issue("suspicious_activity_detected", {
        status: "confirmed",
        additional_description: description,
        source: source,
        proof: "This IP was detected as suspicious in #{source}",
        details: result ,
        references: []
      })

      # Also store it on the entity
      blocked_list = @entity.get_detail(" ") || []
      @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{source: source}]))
    # if error return
    else
      _log_error "data is unreachable !"
      return
    end

  end # end run

end #end class
end
end
