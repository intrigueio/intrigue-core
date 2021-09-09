module Intrigue
module Task
class MobileIronCve202015506 < BaseTask

  def self.metadata
    {
      :name => "vuln/mobileiron_multiple_cves",
      :pretty_name => "Vuln Check - MobileIron Multiple CVEs (CVE-2020-15505, CVE-2020-15506, CVE-2020-15507) ",
      :authors => ["shpendk", "jcran"],
      :identifiers => [{ "cve" =>  "CVE-2020-15505" }, { "cve" =>  "CVE-2020-15506" }, { "cve" =>  "CVE-2020-15507" }],
      :description => "This task does a version check for multiple MobileIron vulnerabilities",
      :references => ["https://nvd.nist.gov/vuln/search/results?form_type=Advanced&cves=on&cpe_version=cpe%3a%2fa%3amobileiron%3acore%3a10.6"],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    # check our fingerprints for a version
    our_version = nil
    fp = _get_entity_detail("fingerprint")
    fp.each do |f|
      if f["vendor"] == "MobileIron" && f["product"] == "Core" && f["version"] != ""
        our_version = f["version"]
        break
      end
    end

    if our_version
      _log "Got version: #{our_version}"
    else
      _log_error "Unable to get version, failing"
      return
    end

    # check the version to see if its vulnerable.
    # versions smaller than 10.6 are vulnerable as per https://www.mobileiron.com/en/blog/mobileiron-security-updates-available
    _log "Checking version against known vulnerable versions"

    if ::Versionomy.parse(our_version) <= ::Versionomy.parse("10.6")
      _log_good "Vulnerable!"
      _create_linked_issue("mobileiron_multiple_cves", {
        proof: {
          detected_version: our_version
        }
      })
    else
      _log "Not vulnerable!"
    end
  end

end
end
end
