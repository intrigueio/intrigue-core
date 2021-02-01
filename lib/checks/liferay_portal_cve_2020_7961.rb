
module Intrigue

  module Issue
    class LiferayPortalCve20207961 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-01-30",
        name: "liferay_portal_cve_2020_7961",
        pretty_name: "Liferay Portal CVE-2020-7961",
        identifiers: [{ type: "CVE", name: "CVE-2020-7961" }],
        severity: 1,
        status: "confirmed",
        category: "vulnerability",
        description: "A Java deserialization vulnerability exists in Liferay Portal's JSON Web Services (JSONWS). Success exploitation allows an unauthorized attacker to perform remote code execution in Liferay Portal versions 7.2.0 and earlier",
        remediation: "Update to the latest Liferay Portal version.",
        affected_software: [
            { :vendor => "Liferay", :product => "Liferay Portal"}
        ],
        references: [
            { type: "description", uri: "https://portal.liferay.dev/learn/security/known-vulnerabilities/-/asset_publisher/HbL5mxmVrnXW/content/id/117954271" },
            { type: "description", uri: "https://attackerkb.com/topics/rXLP28C1nf/cve-2020-7961?referrer=notificationEmail#rapid7-analysis" },
            { type: "exploit", uri: "https://www.rapid7.com/db/modules/exploit/multi/http/liferay_java_unmarshalling/" }
        ],
        authors: ["shpendk", "Markus Wulftange", "Thomas Etrillard", "wvu"]
      }.merge!(instance_details)
      end

    end
  end  
  

  module Task
    class LiferayPortalCve20207961 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"],
          example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
          allowed_options: []
        }
      end

      def check
        # get version for product
        version = get_version_for_vendor_product(@entity, "Liferay", "Portal")
        return false unless version

        # remove update part of if present
        version = version.split(":")[0]

        # split version into major/minor parts
        is_vulnerable = false
        version_parts = version.split(".")
        return false unless version_parts[0] && version_parts[1] && version_parts[2]
        
        # compare based on major/minor version, 
        # based on https://portal.liferay.dev/learn/security/known-vulnerabilities/-/asset_publisher/HbL5mxmVrnXW/content/id/117954271
        case version_parts[0]
        when "6"
          is_vulnerable = compare_versions_by_operator(version, "6.2.5" , "<")
        when "7"
          case version_parts[1]
          when "0"
            is_vulnerable = compare_versions_by_operator(version, "7.0.6" , "<")
          when "1"
            is_vulnerable = compare_versions_by_operator(version, "7.1.3" , "<")
          when "2"
            is_vulnerable = compare_versions_by_operator(version, "7.2.1" , "<")
          end
        end

        return is_vulnerable
      end

    end
  end

end