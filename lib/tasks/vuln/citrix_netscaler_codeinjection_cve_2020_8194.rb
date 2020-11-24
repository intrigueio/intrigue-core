module Intrigue
module Task
class  CitrixNetscalerCve20208194 < BaseTask

  def self.metadata
    {
      :name => "vuln/citrix_netscaler_codeinjection_cve_2020_8194",
      :pretty_name => "Vuln Check - Citrix Netscaler Code Injection (CVE-2019-8194)",
      :authors => ["shpendk","jcran"],
      :description => "This task checks a Citrix Netscaler for the CVE-2019-8194 code injection vulnerability.",
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

    # make request and save response
    response = http_request :get, "#{url}/menu/guiw?nsbrand=1&protocol=nonexistent.1337\">&id=3&nsvpx=phpinfo"
    unless response && response.code.to_i == 200
      _log "No response! Failing"
      return
    end

    # grab response headers and body
    response_headers = response.headers
    response_body = response.body_utf8

    # check if header and body contain needed values
    if response_headers.has_value?("application/x-java-jnlp-file")
      # header is present, check for response body
      if response_body =~ /\<jnlp codebase\=\"nonexistent\.1337\"/
        _log "Vulnerable!"
        _create_linked_issue "citrix_netscaler_codeinjection_cve_2020_8194" , { "proof" => response }
      end
    else
      _log "Not vulnerable!"
    end

  end

end
end
end
