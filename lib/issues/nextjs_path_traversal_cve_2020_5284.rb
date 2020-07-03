module Intrigue
module Issue
class NextjsPathTraversalCve20205284 < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "nextjs_path_traversal_cve_2020_5284",
      pretty_name: "Next.js Path Traversal",
      severity: 2,
      category: "application",
      status: "confirmed",
      description:  "Next.js versions before 9.3.2 have a directory traversal vulnerability. Attackers could craft special requests to access files in the dist directory (.next). This does not affect files outside of the dist directory (.next). In general, the dist directory only holds build assets unless your application intentionally stores other assets under this directory. This issue is fixed in version 9.3.2.",
      remediation:  "Upgrade the software.",
      affected_software: [ { :vendor => "Zeit", :product => "Next.js" } ],
      references: [
        { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-5284" }
      ],
      check: "vuln/nextjs_path_traversal_cve_2020_5284"
    }.merge!(instance_details)

  to_return
  end

end
end
end
