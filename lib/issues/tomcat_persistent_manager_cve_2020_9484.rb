module Intrigue
  module Issue
  class VulnTomcatPersistentManagerCve20209484 < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "tomcat_persistent_manager_cve_2020_9484",
        pretty_name: "Vulnerable Tomcat - Deserialization in Filestore (CVE-2020-9484)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-9484" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "When using Apache Tomcat versions 10.0.0-M1 to 10.0.0-M4, 9.0.0.M1 to 9.0.34, 8.5.0 to 8.5.54 and 7.0.0 to 7.0.103 if a) an attacker is able to control the contents and name of a file on the server; and b) the server is configured to use the PersistenceManager with a FileStore; and c) the PersistenceManager is configured with sessionAttributeValueClassNameFilter=\"null\" (the default unless a SecurityManager is used) or a sufficiently lax filter to allow the attacker provided object to be deserialized; and d) the attacker knows the relative file path from the storage location used by FileStore to the file the attacker has control over; then, using a specifically crafted request, the attacker will be able to trigger remote code execution via deserialization of the file under their control. Note that all of conditions a) to d) must be true for the attack to succeed.",
        remediation: "File store is largely for debugging. Move to JDBC Session store",
        affected_software: [
          { :vendor => "Tomcat", :product => "Tomcat", :version => "7" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "8" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "9" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "10" }
        ],
        references: [ # description, remediation, detection rule, exploit, threat intel
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-9484" },
          { type: "description", uri: "https://www.redtimmy.com/java-hacking/apache-tomcat-rce-by-deserialization-cve-2020-9484-write-up-and-exploit/" },
          { type: "exploit", uri: "https://github.com/masahiro331/CVE-2020-9484" },
          { type: "vulnerable_target", uri: "https://github.com/masahiro331/CVE-2020-9484" },
          { type: "remediation", uri: "https://stackoverflow.com/questions/35917945/tomcat-how-to-persist-a-session-immediately-to-disk-using-persistentmanager" }
        ],
        check: "vuln/tomcat_persistent_manager_cve_2020_9484"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          
  