module Intrigue
module Task
class SearchIPQS < BaseTask


  def self.metadata
    {
      :name => "threat/search_IPQualityScore",
      :pretty_name => "Threat Check - Search IPQualityScore",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits IPQualityScore.com api for IP reputation and nature",
      :references => ["https://www.ipqualityscore.com/documentation/proxy-detection/overview"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["Organization","PhysicalLocation"]
    }
  end


  ## Default method, subclasses must override this
  def run
    super

      #get entity name and type
      entity_name = _get_entity_name

      #get keys for API authorization
      password =_get_task_config("ipqs_api_key")

      headers = { "Accept" =>  "application/json"}

      unless password
        _log_error "unable to proceed, no API key for IpQualityScore provided"
        return
      end

      # Get responce
      response = http_get_body("https://www.ipqualityscore.com/api/json/ip/#{password}/#{entity_name}?strictness=0&allow_public_access_points=true&fast=true&lighter_penalties=true&mobile=true",nil, headers)
      result = JSON.parse(response)
      #puts result

      #Create organization entity
      if response["organization"]
        _create_entity("Organization", {"name" => response["organization"]})
      end

      #Create PhysicalLocation entity
      if response["region"]
        _create_entity("PhysicalLocation", {"name" => response["region"]})
      end

      #create an issue if this IP related to fraud
      if result["success"] and result["fraud_score"] > 0
        _create_linked_issue("suspicious_activity_detected", {
          status: "confirmed",
          description: "This ip was flagged by IpQualityScore for fraud activites",
          proof: result,
          source: "IpQualityScore.com"
        })

    end
  end #end run



end
end
end
