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
    
    check_url = "#{_get_entity_name}/vpn/login.js"
    response = http_request(:get, check_url)

    # grab header
    last_modified_header = false
    response.each_header{|h| last_modified_header = response[h] if h =~ /Last-Modified/i}
    unless last_modified_header
      _log "No Last-Modified Header! Failing"
      return
    end

    # Get the date to see it's vuln
    date_string = last_modified_header.gsub("Last-Modified:","").strip
    _log "Got Date String: #{date_string}"
    # check that it matches our known vuln versions

    if Time.parse(date_string) < Time.parse("Sun, 17 Dec 2019 00:00:00 GMT")
      _log "Vulnerable, got date string: #{date_string}!"
      _create_issue({
        name: "Vulnerable Citrix Netscaler",
        severity: 1,
        type: "vulnerability_citrix_netscaler_rce_cve_2019_19871",
        status: "potential",
        description: "This server (#{check_url}) appears vulnerable to an unauthenticated RCE bug announced in December 2019. See references for more details." + 
         "\n\nProof: #{last_modified_header}. \n\nNote that a mitigation may be in place per instruction from Citrix provided shortly after the release of" + 
         " the patch.",
        references: self.class.metadata["references"],
        details: {}
        })
    else
      _log "Not Vulnerable! Proof: #{last_modified_header}"
    end

  end

 
end
end
end
