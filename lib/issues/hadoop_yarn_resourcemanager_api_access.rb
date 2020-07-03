module Intrigue
  module Issue
  class HadoopYarnResourcemanagerApiAccess < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "hadoop_yarn_resourcemanager_api_access",
        pretty_name: "Hadoop YARN ResourceManager API Access",
        severity: 1,
        category: "application",
        status: "confirmed",
        description: "Hadoop Yarn ResourceManager controls the computation and storage resources of" + 
                     " a Hadoop cluster. Unauthenticated ResourceManager API allows any" + 
                     " remote users to create and execute arbitrary applications on the" + 
                     " host.",
        remediation: "Investigate the page and ensure all resources are loaded over HTTPS.",
        affected_software: [
          { :vendor => "Hadoop", :product => "YARN" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://github.com/google/tsunami-security-scanner-plugins/blob/master/google/detectors/exposedui/hadoop/yarn/src/main/java/com/google/tsunami/plugins/detectors/exposedui/hadoop/yarn/YarnExposedManagerApiDetector.java" }
        ], 
        check: "vuln/hadoop_yarn_unauthenticated_check"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  