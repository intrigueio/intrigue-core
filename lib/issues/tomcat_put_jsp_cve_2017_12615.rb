module Intrigue
  module Issue
  class VulnTomcatPutCve201712615 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "vuln/tomcat_put_jsp_cve_2017_12615",
        pretty_name: "Vulnerable Tomcat - PUT JSP (CVE-2017-12615)",
        identifiers: [
          { type: "CVE", name: "CVE-2017-12615" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "When running Apache Tomcat 7.0.0 to 7.0.79 on Windows with HTTP PUTs enabled (e.g. via setting the readonly initialisation parameter of the Default to false) it was possible to upload a JSP file to the server via a specially crafted request. This JSP could then be requested and any code it contained would be executed by the server.",
        remediation: "Update the Tomcat instance",
        affected_software: [
          { :vendor => "Apache", :product => "Tomcat", :version_from => "7.0.0", :version_to => "7.0.79" },
        ],
        references: [ # description, remediation, detection rule, exploit, threat intel
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2017-12615" },
          { type: "exploit", uri: "https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/tomcat_jsp_upload_bypass.rb" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/42966" }
        ],
        check: "vuln/tomcat_put_jsp_cve_2017_12615"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          
  