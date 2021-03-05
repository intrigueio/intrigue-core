module Intrigue
module Task
class NextjsPathTraversalCve20205284 < BaseTask

  def self.metadata
    {
      :name => "vuln/nextjs_path_traversal_cve_2020_5284",
      :pretty_name => "Vuln Check - Next.js ./next Path Traversal",
      :authors => ["jcran"],
      :identifiers => [{ "cve" => "CVE-2020-5284" }],
      :description => "Determines if the endpoint is vulnerable to CVE-2020-5284.",
      :references => [],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super
        
    # first, ensure we're fingerprinted
    require_enrichment

    uri = "#{_get_entity_name}/_next/static/../server/pages-manifest.json"
    output = http_get_body uri 

    if output =~ /\{\"\/_app\":\".*?_app\.js\"/
      _create_linked_issue("nextjs_path_traversal_cve_2020_5284", { proof: output })
    end

  end

end
end
end
