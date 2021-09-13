module Intrigue
module Task
class MicrosoftExchangeCve20200688 < BaseTask

  def self.metadata
    {
      :name => "vuln/microsoft_exchange_cve_2020_0688",
      :pretty_name => "Vuln Check - Microsoft Exchange RCE (CVE-2020-0688) ",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  "CVE-2020-0688" }],
      :description => "This task does a version check for CVE-2020-0688 in Microsoft Exchange",
      :references => ["https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2020-0688"],
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

      if is_vulnerable_version?(fingerprint)

        # check to see if the vulnerable path is available
        check_url = "#{_get_entity_name}/ecp/default.aspx"
        response = http_request(:get, check_url)

        if response.body_utf8 =~ /<title>Exchange Admin Center/
          _create_linked_issue("vulnerability_exchange_cve_2020_0688", {
            proof: {
              response_body: response.body_utf8
            }
          })
        end

      end
    end
  end

  def is_vulnerable_version?(fingerprint)
    # check the fingerprints
    fp = fingerprint.select{|v| v['product'] == "Exchange Server" }.first
    return false unless fp

    vulnerable_versions.include?({version: fp["version"], update: fp["update"]})
  end

  def vulnerable_versions
    vulnerable_versions = [
      # 2010
      { version: "2010", update: "RTM"},
      { version: "2010", update: "Update Rollup 1"},
      { version: "2010", update: "Update Rollup 2"},
      { version: "2010", update: "Update Rollup 3"},
      { version: "2010", update: "Update Rollup 4"},
      { version: "2010", update: "Update Rollup 4"},
      { version: "2010", update: "Update Rollup 5"},

      # 2010 SP1
      { version: "2010 SP1", update: "RTM"},
      { version: "2010 SP1", update: "Update Rollup 1"},
      { version: "2010 SP1", update: "Update Rollup 2"},
      { version: "2010 SP1", update: "Update Rollup 2"},
      { version: "2010 SP1", update: "Update Rollup 3"},
      { version: "2010 SP1", update: "Update Rollup 3-v3"},
      { version: "2010 SP1", update: "Update Rollup 4"},
      { version: "2010 SP1", update: "Update Rollup 4-v2"},
      { version: "2010 SP1", update: "Update Rollup 5"},
      { version: "2010 SP1", update: "Update Rollup 6"},
      { version: "2010 SP1", update: "Update Rollup 6" },
      { version: "2010 SP1", update: "Update Rollup 7"},
      { version: "2010 SP1", update: "Update Rollup 7-v2"},
      { version: "2010 SP1", update: "Update Rollup 7-v3"},
      { version: "2010 SP1", update: "Update Rollup 8"},

      # 2010 SP2
      { version: "2010 SP2", update: "RTM"},
      { version: "2010 SP2", update: "Update Rollup 1"},
      { version: "2010 SP2", update: "Update Rollup 2"},
      { version: "2010 SP2", update: "Update Rollup 3"},
      { version: "2010 SP2", update: "Update Rollup 4"},
      { version: "2010 SP2", update: "Update Rollup 4-v2"},
      { version: "2010 SP2", update: "Update Rollup 5"},
      { version: "2010 SP2", update: "Update Rollup 5-v2"},
      { version: "2010 SP2", update: "Update Rollup 6"},
      { version: "2010 SP2", update: "Update Rollup 6"},
      { version: "2010 SP2", update: "Update Rollup 7"},
      { version: "2010 SP2", update: "Update Rollup 8"},
      { version: "2010 SP2", update: "Update Rollup 8"},
      # 2010 SP2
      { version: "2010 SP3", update: "RTM"},
      { version: "2010 SP3", update: "Update Rollup 1"},
      { version: "2010 SP3", update: "Update Rollup 2"},
      { version: "2010 SP3", update: "Update Rollup 3"},
      { version: "2010 SP3", update: "Update Rollup 4"},
      { version: "2010 SP3", update: "Update Rollup 5"},
      { version: "2010 SP3", update: "Update Rollup 6"},
      { version: "2010 SP3", update: "Update Rollup 7"},
      { version: "2010 SP3", update: "Update Rollup 8-v2"},
      { version: "2010 SP3", update: "Update Rollup 9"},
      { version: "2010 SP3", update: "Update Rollup 10"},
      { version: "2010 SP3", update: "Update Rollup 11"},
      { version: "2010 SP3", update: "Update Rollup 12"},
      { version: "2010 SP3", update: "Update Rollup 13"},
      { version: "2010 SP3", update: "Update Rollup 14"},
      { version: "2010 SP3", update: "Update Rollup 15"},
      { version: "2010 SP3", update: "Update Rollup 16"},
      { version: "2010 SP3", update: "Update Rollup 16"},
      { version: "2010 SP3", update: "Update Rollup 17"},
      { version: "2010 SP3", update: "Update Rollup 18"},
      { version: "2010 SP3", update: "Update Rollup 19"},
      { version: "2010 SP3", update: "Update Rollup 19" },
      { version: "2010 SP3", update: "Update Rollup 20"},
      { version: "2010 SP3", update: "Update Rollup 21" },
      { version: "2010 SP3", update: "Update Rollup 21"},
      { version: "2010 SP3", update: "Update Rollup 21" },
      { version: "2010 SP3", update: "Update Rollup 22"},
      { version: "2010 SP3", update: "Update Rollup 22" },
      { version: "2010 SP3", update: "Update Rollup 23"},
      { version: "2010 SP3", update: "Update Rollup 24"},
      { version: "2010 SP3", update: "Update Rollup 25"},
      { version: "2010 SP3", update: "Update Rollup 25"},
      { version: "2010 SP3", update: "Update Rollup 26"},
      { version: "2010 SP3", update: "Update Rollup 27"},
      { version: "2010 SP3", update: "Update Rollup 28"},
      { version: "2010 SP3", update: "Update Rollup 29"},
      { version: "2010 SP3", update: "Update Rollup 29"},
      #{ version: "2010 SP3", update: "Update Rollup 30" },

      # 2013
      { version: "2013", update: "RTM" },
      { version: "2013", update: "Cumulative Update 1" },
      { version: "2013", update: "Cumulative Update 2" },
      { version: "2013", update: "Cumulative Update 3" },
      { version: "2013", update: "Cumulative Update 4" },
      { version: "2013", update: "Cumulative Update 5" },
      { version: "2013", update: "Cumulative Update 6" },
      { version: "2013", update: "Cumulative Update 7" },
      { version: "2013", update: "Cumulative Update 8" },
      { version: "2013", update: "Cumulative Update 9" },
      { version: "2013", update: "Cumulative Update 10" },
      { version: "2013", update: "Cumulative Update 11" },
      { version: "2013", update: "Cumulative Update 12" },
      { version: "2013", update: "Cumulative Update 13" },
      { version: "2013", update: "Cumulative Update 14" },
      { version: "2013", update: "Cumulative Update 15" },
      { version: "2013", update: "Cumulative Update 16" },
      { version: "2013", update: "Cumulative Update 17" },
      { version: "2013", update: "Cumulative Update 18" },
      { version: "2013", update: "Cumulative Update 19" },
      { version: "2013", update: "Cumulative Update 20" },
      { version: "2013", update: "Cumulative Update 21" },
      { version: "2013", update: "Cumulative Update 22" },
      #{ version: "2013", update: "Cumulative Update 23" },
      #{ version: "2013", update: "Cumulative Update 23" },

      # 2016
      { version: "2016", update: "Preview" },
      { version: "2016", update: "RTM" },
      { version: "2016", update: "Cumulative Update 1" },
      { version: "2016", update: "Cumulative Update 2" },
      { version: "2016", update: "Cumulative Update 3" },
      { version: "2016", update: "Cumulative Update 4" },
      { version: "2016", update: "Cumulative Update 5" },
      { version: "2016", update: "Cumulative Update 6" },
      { version: "2016", update: "Cumulative Update 7" },
      { version: "2016", update: "Cumulative Update 8" },
      { version: "2016", update: "Cumulative Update 9" },
      { version: "2016", update: "Cumulative Update 10" },
      { version: "2016", update: "Cumulative Update 11" },
      { version: "2016", update: "Cumulative Update 12" },
      { version: "2016", update: "Cumulative Update 13" },
      #{ version: "2016", update: "Cumulative Update 14" },
      #{ version: "2016", update: "Cumulative Update 15" },
      #{ version: "2016", update: "Cumulative Update 15" },

      # 2019
      { version: "2019", update: "Preview" },
      { version: "2019", update: "RTM" },
      { version: "2019", update: "Cumulative Update 1" },
      { version: "2019", update: "Cumulative Update 2" },
      #{ version: "2019", update: "Cumulative Update 3" },

    ]
  end

end
end
end
