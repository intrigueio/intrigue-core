module Intrigue
  module Issue
  class SpringInfoLeak < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "spring_info_leak",
        pretty_name: "Spring Info Leak",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "This site is leaking sensitve infomration via a exposed path.",
        remediation: "Investigate the endpoint and place it behind authenication if it should not be exposed.",
        affected_software: [
          { :vendor => "Pivotal Software", :product => "Spring Boot" },
          { :vendor => "Pivotal Software", :product => "Spring Framework" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://howtodoinjava.com/spring-boot/actuator-endpoints-example/" }
        ],
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end

  end
  end
  end