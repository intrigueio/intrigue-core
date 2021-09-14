module Intrigue
module Task
class SearchIPQSEmailAddress < BaseTask


  def self.metadata
    {
      :name => "search_IPQualityScore_EmailAddress",
      :pretty_name => "Search IPQualityScore EmailAddress",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits IPQualityScore.com api for EmailAddress validation ",
      :references => ["https://www.ipqualityscore.com/documentation/email-validation/overview"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [{"type" => "EmailAddress", "details" => {"name" => "test@gmail.com"}}],
      :allowed_options => [],
      :created_types => ["EmailAddress"]
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
      response = http_get_body("https://www.ipqualityscore.com/api/json/email/#{password}/#{entity_name}",nil, headers)
      result = JSON.parse(response)
      #puts result

      #Create organization entity
      if result["success"] == true
        _create_entity("EmailAddress", {"name" => result["sanitized_email"]})
        _set_entity_detail("extended_ipqualityscore",result)
      end

      #create an issue if this IP related to fraud
      if result["leaked"]== true or result["suspect"] == true or result["spam_trap_score"] != "none"
        _create_linked_issue("suspicious_activity_detected", {
          status: "confirmed",
          description: "This Email Address was flagged by IpQualityScore for these reasons: Leak:#{result["leaked"]} // suspicious activity:#{result["suspect"]} // Spam:#{result["spam_trap_score"]} ",
          proof: result,
          source: "IpQualityScore.com"
        })
      end
  end #end run

end
end
end
