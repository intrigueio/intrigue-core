module Intrigue
module Task
class SearchDshield < BaseTask


  def self.metadata
    {
      :name => "threat/search_dshield",
      :pretty_name => "Threat Check - Search Dshield",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Dshield api for Ip reputation and threat feeds ",
      :references => ["https://www.dshield.org/api/#ip"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super

      #get entity name and type
      entity_name = _get_entity_name

      #headers
      headers = { "Accept" =>  "application/json"}

      # Get responce
      response = http_get_body("https://www.dshield.org/api/ip/#{entity_name}?json",nil,headers)
      result = JSON.parse(response)

      if result["attacks"] != "null" or result["maxrisk"] != "null"
        _create_linked_issue("suspicious_activity_detected", {
          status: "confirmed",
          description: "This ip was flagged by Dshield for malicious activites",
          proof: result,
          source: "Dshield.org"
        })
        # Also store it on the entity
        blocked_list = @entity.get_detail("suspicious_activity_detected") || []
        @entity.set_detail("suspicious_activity_detected", blocked_list.concat([{}]))
    end
  end #end run



end
end
end
