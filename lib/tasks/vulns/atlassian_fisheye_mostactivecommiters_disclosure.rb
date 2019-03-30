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
      :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
      :allowed_options => [  ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    ## https://url/fe/mostActiveCommitters.do?path=&repname=REPONAME&maxCommitters=9&numDays=90
    # https://fisheye.student.fiw.fhws.de:8443/fe/mostActiveCommitters.do?path=&repname=lambeth&maxCommitters=9&numDays=90


  end

end
end
end
