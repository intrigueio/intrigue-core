module Intrigue
module Task
class SaasServicenowCheck < BaseTask

  def self.metadata
    {
      :name => "saas_servicenow_check",
      :pretty_name => "SaaS ServiceNow Check",
      :authors => ["jcran"],
      :description => "Checks to see if hosted ServiceNow account exists for a given domain or org",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","Organization", "String", "WebAccount"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => ["WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    if _get_entity_type_string == "WebAccount"
      account_name = _get_entity_detail("username")      
    else 
      account_name = _get_entity_name
    end

    # try a couple variations
    if _get_entity_type_string == "Domain" && account_name =~ /\./
      check_and_create account_name.split(".").first
      check_and_create account_name.gsub(".","")
      check_and_create "#{account_name.split(".")[0...-1].join("")}"
    else
      check_and_create account_name
    end

  end

  def check_and_create(account_name)
    url = "https://#{account_name}.service-now.com"
    # https://company.service-now.com/kb_view_customer.do?sysparm_article=KB00xxxx

    # grab the page 
    body = http_get_body url

    if body
      _log_good "The #{account_name} org exists!"

      service_name = "servicenow"
      _create_normalized_webaccount service_name, account_name, url
    else
      _log_error "Unknown response! Unable to continue"
    end
  end

end
end
end
