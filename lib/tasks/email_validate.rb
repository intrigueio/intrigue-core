module Intrigue
class EmailValidateTask < BaseTask
  include Intrigue::Task::Web


  def metadata
    {
      :name => "email_validate",
      :pretty_name => "Email Validate",
      :authors => ["jcran"],
      :description => "This task validates an email via the email-validator.net API.",
      :requires_config => [""],
      :references => [],
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

    email_address = _get_entity_attribute "name"
    api_key = _get_global_config "email_validator_apikey"
    uri = "http://api.email-validator.net/api/verify?EmailAddress=#{email_address}&APIKey=#{api_key}"

    email_validation_results = JSON.parse http_get_body(uri)
    @task_result.logger.log "Got result: #{email_validation_results["status"]}"

    if email_validation_result["info"] =~ /Valid Address/
      _create_entity "Info", email_validation_results.merge({"name" => "Valid Address: #{email_address}"})
    end
  end

end
end
