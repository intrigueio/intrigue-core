module Intrigue
module Task
class MicrosoftExchangeCve202016875 < BaseTask

  def self.metadata
    {
      :name => "vuln/microsoft_exchange_cve_2020_16875",
      :pretty_name => "Vuln Check - Microsoft Exchange RCE (CVE-2020-16875) ",
      :authors => ["shpendk","jcran"],
      :identifiers => [{ "cve" =>  "CVE-2020-16875" }],
      :description => "This task does a version check for CVE-2020-16875 in Microsoft Exchange",
      :references => ["https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2020-16875"],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [{:name => "force", :regex => "boolean", :default => false }],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # first, ensure we're fingerprinted
    require_enrichment
    fingerprint = _get_entity_detail("fingerprint")

    if is_product?(fingerprint, "Exchange Server")

      # check the fingerprints
      fp = fingerprint.select{|v| v['product'] == "Exchange Server" }.first
      return "No fingerprint found for the product in question" unless fp
      
      if is_vulnerable_version?(fp)
        _create_linked_issue("microsoft_exchange_cve_2020_16875", {
          proof: {
            detected_version: fp["version"],
            detected_update: fp["update"]
          }
        })
      end
    end
  end

  def is_vulnerable_version?(fp)
    vulnerable_versions.include?({version: fp["version"], update: fp["update"]})
  end

  def vulnerable_versions
    vulnerable_versions = [

      # 2016
      { version: "2016", update: "Cumulative Update 16" },
      { version: "2016", update: "Cumulative Update 17" },

      # 2019
      { version: "2019", update: "Cumulative Update 5" },
      { version: "2019", update: "Cumulative Update 6" },
    ]
  end

end
end
end
