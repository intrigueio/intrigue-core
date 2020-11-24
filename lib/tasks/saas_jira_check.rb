module Intrigue
module Task
class SaasJiraCheck < BaseTask

  def self.metadata
    {
      :name => "saas_jira_check",
      :pretty_name => "SaaS Jira Check",
      :authors => ["jcran"],
      :description => "Checks to see if hosted Jira account for a given domain or org",
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

    entity_name = _get_entity_name

    # try a couple variations
    if _get_entity_type_string == "Domain" && entity_name =~ /\./
      check_and_create entity_name.split(".").first
      check_and_create entity_name.gsub(".","")
      check_and_create "#{entity_name.split(".")[0...-1].join("")}"
    else
      check_and_create entity_name
    end

  end

  def check_and_create(name)
    url = "https://#{name}.atlassian.net/login"

    # grab the page 
    body = http_get_body url

    if body =~ /Log in to Jira, Confluence, and all other Atlassian Cloud products here/
      _log_good "The #{name} org exists!"

      service_name = "atlassian.net"
      _create_normalized_webaccount(service_name, name, url)

    elsif body =~ /Your Atlassian Cloud site is currently unavailable./
      _log_error "Nothing found for #{name}"
    else
      _log_error "Unknown response! Unable to continue"
    end
  end

end
end
end
