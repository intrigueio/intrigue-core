module Intrigue
module Task
class  CitrixNetscalerRceCVE201919781 < BaseTask

  def self.metadata
    {
      :name => "vuln/citrix_netscaler_rce_cve_2019_19781",
      :pretty_name => "Vuln - Citrix Netscaler RCE (CVE-2019-19781)",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  "CVE-2019-19781" }],
      :description => "This task checks checks a Citrix Netscaler for a version vulnerable to the Dec 2019 /vpns RCE.",
      :references => [
          "https://support.citrix.com/article/CTX267027",
          "https://support.citrix.com/article/CTX267679"
      ],
      :type => "vuln",
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

    check_url = "#{_get_entity_name}/vpn/../vpns/cfg/smb.conf"
    response = http_request(:get, check_url)

    # grab header
    unless response && response.body 
      _log "No response! Failing"
      return
    end
    
    if response.code.to_i == 200

      # check that it matches our known vuln versions
      if response.body =~ /\[global\]/
        _log "Vulnerable!"
        _create_issue({
          name: "Vulnerable Citrix Netscaler",
          severity: 1,
          type: "vulnerability_citrix_netscaler_rce_cve_2019_19871",
          status: "potential",
          category: "network",
          description: "This server (#{check_url}) is vulnerable to an unauthenticated RCE bug announced in December 2019. See references for more details.\n\nProof: Positive match on response body.",
          references: self.class.metadata["references"],
          details: {
            "response_body" => response.body,
            "response_code" => response.code
          }
          })
      else
        _log "Not Vulnerable, couldnt match our regex: #{response.body}"
      end
    elsif response.code.to_i == 403
      _log "Not Vulnerable, invalid code: #{response.code}"
    end

  end

 
end
end
end
