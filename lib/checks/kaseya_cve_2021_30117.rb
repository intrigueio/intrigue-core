
module Intrigue

  module Issue
    class KaseyaCve202130117 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-07-09",
        name: "kaseya_cve_2021_30117",
        pretty_name: "Kaseya Credential Disclosure (CVE-2021-30117)",
        identifiers: [
          { type: "CVE", name: "CVE-2021-30117" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "potential",
        description: "SQL injection exists in Kaseya VSA before 9.5.6.",
        affected_software: [ 
          { :vendor => "Kaseya", :product => "Virtual System Administrator" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-30117" },
          { type: "description", uri: "https://helpdesk.kaseya.com/hc/en-gb/articles/4403440684689-Important-Notice-July-2nd-2021" }
        ],
        authors: ["shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class KaseyaCve202130117 < BaseCheck 
    def self.check_metadata
      {
        allowed_types: ["Uri"]
      }
    end

    # return truthy value to create an issue
    def check

      # get enriched entity
      require_enrichment

      # get version for product
      version = get_version_for_vendor_product(@entity, 'Kaseya', 'Virtual System Administrator')
      return false unless version

      # if its vulnerable, return some proof
      if compare_versions_by_operator(version, "9.5.6" , "<")
        return "Asset is vulnerable based on fingerprinted version #{version}"
      end
    end

    end
  end
  
  end
