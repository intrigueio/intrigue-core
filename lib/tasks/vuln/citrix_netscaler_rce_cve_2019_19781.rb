module Intrigue
module Task
class  CitrixNetscalerRceCVE201919781 < BaseTask

  def self.metadata
    {
      :name => "vuln/citrix_netscaler_rce_cve_2019_19781",
      :pretty_name => "Vuln Check - Citrix Netscaler RCE (CVE-2019-19781)",
      :authors => ["jcran"],
      :description => "This task checks checks a Citrix Netscaler for a version vulnerable to the Dec 2019 /vpns RCE.",
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

    check_url = "#{_get_entity_name}/vpn/../vpns/cfg/smb.conf"
    response = http_request(:get, check_url)

    # grab header
    unless response && response.body_utf8 
      _log "No response! Failing"
      return
    end
    
    if response.code.to_i == 200

      # check that it matches our known vuln versions
      if response.body_utf8 =~ /\[global\]/
        _log "Vulnerable!"
        # file issue
        _create_linked_issue("citrix_netscaler_rce_cve_2019_19781", { 
          status: "confirmed", 
          checked_url: check_url,
          proof: response.body_utf8 })
      else
        _log "Not Vulnerable, couldnt match our regex: #{response.body_utf8}"
      end
    elsif response.code.to_i == 403
      _log "Not Vulnerable, invalid code: #{response.code}"
    end

  end

 
end
end
end
