###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
module Task
class  WebminPwresetCve201915107 < BaseTask

  def self.metadata
    {
      :name => "vuln/webmin_pwreset_cve_2019_15107",
      :pretty_name => "Vuln Check - Webmin Password Reset Check",
      :authors => ["jcran","AkkuS <Özkan Mustafa Akkuş>"],
      :identifiers => [{ "cve" =>  "CVE-2019-15107" }],
      :description => "Check for a webmin unauthenticated RCE. Requires a specific configuration, see references.",
      :references => [
        "https://pentest.com.tr/exploits/DEFCON-Webmin-1920-Unauthenticated-Remote-Command-Execution.html"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    vulnerable_version = "1.920"

    # check our fingerprints for a version
    our_version = nil
    fp = _get_entity_detail("fingerprint")
    fp.each do |f|
      if f["product"] == "Webmin" && f["version"] != ""
        our_version = f["version"]
        break
      end
    end

    if our_version
      _log "Got version: #{our_version}"

      if ::Versionomy.parse(our_version) <= ::Versionomy.parse(vulnerable_version)
        _log_good "Potentially Vulnerable!"

        ###
        # check passwd change priv
        ####
        url = "#{_get_entity_name}/password_change.cgi"
        cookies = "redirect=1; testing=1; sid=x; sessiontest=1"
        headers = { "Referer" => "#{_get_entity_name}/session_login.cgi", "Cookie" => cookies }
        res = http_request :post, url, nil, headers

        # make sure we got a response
        unless res
          _log "Not vulnerable, no response!"
          return
        end

        # check to see if we got a failure immediately
        if res.code == 500 && res.body =~ /Password changing is not enabled/
          _log "Not vulnerable, Password changing not enabled!"
          return
        end

        ### okay if we made it this far, create an issue
        _create_linked_issue("vulnerability_webmin_cve_2019_15107", {
          proof: {
            detected_version: our_version,
            response_code: res.code,
            response_body: res.body
          }
        })
      else
        _log "Version #{our_version} is newer than vulnerable version: #{vulnerable_version}"

      end

    else
      _log_error "Unable to get version, failing"
      return
    end

  end


end
end
end
