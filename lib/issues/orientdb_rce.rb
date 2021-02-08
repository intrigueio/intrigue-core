module Intrigue
    module Issue
    class OrientdbRce < BaseIssue
    
      def self.generate(instance_details={})
        {
          added: "2021-01-28",
          name: "orientdb_rce",
          pretty_name: "OrientDB Remote Code Execution",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "A privilege escalation in OrientDB versions between 2.2.2 and 2.2.22 allows for remote code execution via unsandboxed OS commands.",
          remediation: "Update to the latest version of OrientDB.",
          affected_software: [
            { :vendor => "Orientdb", :product => "Orientdb" }
          ],
          references: [
            { type: "description", uri: "https://ssd-disclosure.com/ssd-advisory-orientdb-code-execution/" },
            { type: "exploit", uri: "https://www.exploit-db.com/exploits/42965" },
          ],
          check: "vuln/orientdb_rce"
        }.merge!(instance_details)
      end
    
    end
    end
    end