module Intrigue
module Issue
class DirectoryListingDetected < BaseIssue

  def self.generate(instance_details)
    to_return = {
      added: "2020-01-01",
      name: "directory_listing_detected",
      pretty_name: "Directory Listing Detected",
      severity: 4,
      status: "confirmed",
      category: "application",
      description: "Directory listing is a feature that when enabled the web servers list the content of a directory when there is no index file (e.g. index.php or index.html) present. Therefore if a request is made to a directory on which directory listing is enabled, and there is no index file such as index.php or index.asp, even if there are files from a web application, the web server sends a directory listing as a response. When this happens there is an information leakage issue, and the attackers can use such information to craft other attacks, including direct impact vulnerabilities such as LFI and XSS",
      remediation: "Inspect for sensitive files, and disable the listing unless it's intentional.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://www.netsparker.com/blog/web-security/disable-directory-listing-web-servers/"}
      ],
      # task: handled in ident
    }.merge!(instance_details)

  to_return
  end

end
end
end
