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
      :allowed_options => [  ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    # https://URL/plugins/servlet/oauth/users/icon-uri?consumerUri=https://127.0.0.1


  end

end
end
end
