module Intrigue
module Issue
class VulnerableTomcatJmxConsole < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "vulnerable_tomcat_jmx_console",
      pretty_name: "Apache Tomcat JMX Console Exposed",
      identifiers: [],
      severity: 1,
      category: "misconfiguration",
      status: "confirmed",
      description: "This server is exposing a sensitive path",
      remediation: "Adjust access controls or remove these files from the server.",
      affected_software: [
        { :vendor => "Apache", :product => "Tomcat" }
      ],
      references: [
        { type: "description", uri: "https://tomcat.apache.org/tomcat-8.5-doc/security-howto.html#JMX" }
      ],
      task: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end