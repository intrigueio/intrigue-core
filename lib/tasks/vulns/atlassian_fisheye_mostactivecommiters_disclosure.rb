module Intrigue
module Task
class AtlassianFisheyeMostactivecommitersDisclosure < BaseTask

  def self.metadata
    {
      :name => "vuln/atlassian_fisheye_mostactivecommiters_disclosure",
      :pretty_name => "Vuln - Atlassian Fisheye mostactivecommiters.do Information Disclosure",
      :identifiers => [{ "cve" =>  "CVE-2017-9512" }],
      :authors => ["jcran"],
      :description => "Information disclosure in Fisheye",
      :references => [
        "https://jira.atlassian.com/browse/FE-6892",
        "https://jira.atlassian.com/browse/CRUC-8053"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "project_name", :type => "alpha_numeric", :regex => "boolean", :default => false },
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name
    opt_project_name = _get_option "project_name"

    begin
      j = JSON.parse = http_get_body "#{uri}/fe/mostActiveCommitters.do?path=&repname=#{project_name}&maxCommitters=9&numDays=90"

      ############################################
      ###      Old Issue                      ###
      ###########################################
      # _create_issue({
      #   name: "Vulnerable to Atlassian Fisheye mostactivecommiters.do Information Disclosure (CVE-2017-9512)",
      #   type: "vulnerability",
      #   severity: 1,
      #   status: "confirmed",
      #   description: "Vulnerable to Atlassian Fisheye mostactivecommiters.do Information Disclosure (CVE-2017-9512)",
      #   details: {
      #     uri: uri,
      #     cve_id: "CVE-2017-9512",
      #     project_name: "#{opt_project_name}",
      #   }
      # })
      ############################################
      ####            New Issue               ####
      ############################################
      _create_linked_issue("atlassian_fisheye_mostactivecommiters_cve_2017_9512",{
        detailed_description: "The mostActiveCommitters.do resource in Atlassian FishEye and Crucible, before version 4.4.1 allows anonymous remote attackers to access sensitive information, for example email addresses of committers, as it lacked permission checks.",
        details: {
          uri: uri,
          cve_id: "CVE-2017-9512",
          project_name: "#{opt_project_name}",
        }
      })
    rescue JSON::ParserError => e
      _log_error "Unable to parse response. Not vulnerable?"
    end

  end

end
end
end
