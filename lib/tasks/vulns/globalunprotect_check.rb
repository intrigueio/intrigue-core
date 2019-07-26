###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
module Task
class  GlobalunprotectCheck < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "vuln/globalunprotect_check",
      :pretty_name => "Vuln - Globalunprotect Check",
      :authors => ["jcran"],
      :description => "This task checks for the Palo Alto Globalprotect vulnerability announced by Orange Tsai prior to Black Hat 2019.",
      :references => [
        "https://blog.orange.tw/2019/07/attacking-ssl-vpn-part-1-preauth-rce-on-palo-alto.html",
        "https://www.blackhat.com/us-19/briefings/schedule/#infiltrating-corporate-intranet-like-nsa---pre-auth-rce-on-leading-ssl-vpns-15545"
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
    
    check_url = "#{_get_entity_name}/global-protect/portal/css/login.css"
    response = http_request(:get, check_url)

    # grab header
    last_modified_header = false
    response.each_header{|h| last_modified_header = response[h] if h =~ /Last-Modified/i}
    unless last_modified_header
      _log "No Last-Modified Header! Failing"
      return
    end

    # check that it matches our vuln versions
    if last_modified_header =~ /^Last-Modified:.*(Jan 2018|Feb 2018|Mar 2018|Apr 2018|May 2018|Jun 2018|2017).*$/i
      _log "Vulnerable! #{output.strip}"
      _create_issue({
        name: "System vulnerable to a remote unauthenticated RCE: #{to_scan}",
        severity: 1,
        type: "vulnerability_globalunprotect",
        status: "confirmed",
        description: "This server is vulnerable to an unauthenticated RCE bug announced in July 2019. No CVE exists. See references for more details.",
        references: self.metadata["references"]
        })
    else
      _log "Not Vulnerable! Last-Modified Header:  #{last_modified_header.strip}"
    end

  end

 
end
end
end
