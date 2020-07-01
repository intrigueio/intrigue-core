module Intrigue
module Task
class  PaloAltoGlobalprotectCheck < BaseTask

  def self.metadata
    {
      :name => "vuln/paloalto_globalprotect_check",
      :pretty_name => "Vuln Check - PaloAlto GlobalProtect RCE",
      :authors => ["jcran","orange_8361","mehqq_"],
      :identifiers => [{ "cve" =>  "CVE-2019-1579" }],
      :description => "This task checks for the Palo Alto Globalprotect vulnerability announced by Orange Tsai prior to Black Hat 2019.",
      :references => [
        "https://blog.orange.tw/2019/07/attacking-ssl-vpn-part-1-preauth-rce-on-palo-alto.html",
        "https://www.blackhat.com/us-19/briefings/schedule/#infiltrating-corporate-intranet-like-nsa---pre-auth-rce-on-leading-ssl-vpns-15545",
        "cve-2019-1579-critical-pre-authentication-vulnerability-in-palo-alto-networks-globalprotect-ssl"
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
    
    check_url = "#{_get_entity_name}/global-protect/portal/css/login.css"
    response = http_request(:get, check_url)

    # grab header
    last_modified_header = false
    response.each_header{|h| last_modified_header = response[h] if h =~ /Last-Modified/i}
    unless last_modified_header
      _log "No Last-Modified Header! Failing"
      return
    end

    # Get the date to see it's vuln
    matches = last_modified_header.match(/(Jan 2018|Feb 2018|Mar 2018|Apr 2018|May 2018|Jun 2018|2017|2016)/i)

    # check that it matches our known vuln versions
    vuln_versions = ["Jan 2018","Feb 2018","Mar 2018","Apr 2018","May 2018","Jun 2018","2017","2016"]
    if matches && matches.captures
      date = matches.captures.first.strip
      _log "Checking... #{last_modified_header}, date: #{date}"
      vulnerable = true if vuln_versions.include? date
    else
      _log "No capture :["
    end

    # example: Last-Modified: Wed, 06 Jun 2018 20:52:55 GMT
    if vulnerable
      _log "Vulnerable!"
      last_modified_header
      _create_linked_issue("vulnerable_globalprotect_cve_2019_1579", {proof: last_modified_header})
    else
      _log "Not Vulnerable! Header: #{last_modified_header}"
    end

  end

 
end
end
end
