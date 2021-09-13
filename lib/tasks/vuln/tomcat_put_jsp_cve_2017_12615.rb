module Intrigue
module Task
class TomcatPutJsp < BaseTask

  def self.metadata
    {
      :name => "vuln/tomcat_put_jsp_cve_2017_12615",
      :pretty_name => "Vuln Check - Tomcat PUT method",
      :identifiers => [
        { "cve" =>  "CVE-2017-12615" },
        { "metasploit" => "exploits/multi/http/tomcat_jsp_upload_bypass"}
      ],
      :authors => ["jcran"],
      :description => "When running on Windows with HTTP PUTs enabled (e.g. via setting the readonly initialisation parameter of the Default to false) it was possible to upload a JSP file to the server via a specially crafted request. This JSP could then be requested and any code it contained would be executed by the server.",
      :references => [
        "https://github.com/breaktoprotect/CVE-2017-12615",
        "https://www.ixiacom.com/company/blog/deconstructing-apache-tomcat-jsp-upload-remote-code-execution-cve-2017-12615",
        "https://www.peew.pw/blog/2017/10/9/new-vulnerability-same-old-tomcat-cve-2017-12615",
        "https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/tomcat_jsp_upload_bypass.rb"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
      :allowed_options => [  ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    uri = _get_entity_name

    payload = '<% out.write("<html><body><h3>hello world!</h3></body></html>"); %>'

    #docs/manager-howto.jsp
    begin

      response = RestClient::Request.execute(
        :url => "#{uri}/test.jsp/",
        :method => :put,
        :headers => { content_type: 'text/plain'},
        :verify_ssl => false
      )

      unless response
        _log_error "No response received?"
        return
      end

      if response.code == 201
        _log_good "SUCCESS!"
        _log_good "Access the page at:  #{uri}/test.jsp"
        _create_linked_issue("vuln/tomcat_put_jsp_cve_2017_12615", {
          proof: {
            response: response
          }
        })
      end

    rescue Errno::ECONNRESET => e 
      _log_error "connection reset on #{uri}: #{e}"
    rescue RestClient::MovedPermanently => e
      _log_error "301 on #{uri}: #{e}"
    rescue RestClient::MethodNotAllowed => e
      _log_good "405 on #{uri}: NOT VULNERABLE"
    rescue RestClient::ResourceNotFound => e
      _log_error "404 on #{uri}: #{e}"
    rescue RestClient::Forbidden => e
      _log_error "Forbidden on #{uri}: #{e}"
      return
    end

  end

end
end
end
