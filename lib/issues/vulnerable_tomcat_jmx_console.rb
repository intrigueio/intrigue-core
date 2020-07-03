module Intrigue
module Issue
class VulnerableTomcatJmxConsole < BaseIssue

  def self.generate(instance_details={})
    {
      name: "vulnerable_tomcat_jmx_console",
      pretty_name: "Vulnerable ",
      identifiers: [],
      severity: 1,
      category: "vulnerability",
      status: "confirmed",
      description: "This server is exposing a sensitive path",
      remediation: "Adjust access controls or remove these files from the server.",
      affected_software: [
        { :vendor => "Apache", :product => "Tomcat" }
      ],
      references: [],
      check: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end