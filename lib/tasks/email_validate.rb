module Intrigue
class EmailValidateTask < BaseTask
  include Intrigue::Task::Web


  def self.metadata
    {
      :name => "email_validate",
      :pretty_name => "Email Validate",
      :authors => ["jcran"],
      :description => "This task validates an email via the email-validator.net API.",
      :requires_config => [""],
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [
        {"type" => "EmailAddress", "attributes" => {"name" => "test@intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    email_address = _get_entity_name
    api_key = _get_global_config "email_validator_apikey"
    uri = "http://api.email-validator.net/api/verify?EmailAddress=#{email_address}&APIKey=#{api_key}"

    email_validation_results = JSON.parse http_get_body(uri)
    _log "Got result: #{email_validation_results["status"]}"

    if email_validation_results["info"] =~ /Valid Address/
      #_create_entity "Info", email_validation_results.merge({"name" => "Valid Address: #{email_address}"})
      @entity.details["verified"] = true
      @entity.details.merge email_validation_results
    else
      @entity.details["verified"] = false
      @entity.details.merge email_validation_results
    end
  end

end
end
