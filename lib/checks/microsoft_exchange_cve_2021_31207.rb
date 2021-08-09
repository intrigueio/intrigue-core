
module Intrigue

    module Issue
      class MicrosoftExchangeCve202131207 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-08-09",
          name: "microsoft_exchange_cve_2021_31207",
          pretty_name: "Microsoft Exchange Server Security Feature Bypass (CVE-2021-31207)",
          identifiers: [
            { type: "CVE", name: "CVE-2021-31207" }
          ],
          severity: 2,
          status: "potential",
          category: "vulnerability",
          description: "Microsoft Exchange Server Security Feature Bypass Vulnerability",
          remediation: "Install the latest security update for the specific products.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2013"},
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016"},
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019"}
          ],
          references: [
            { type: "description", uri: "https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-31207" },
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-31207"}
          ],
          authors: ["shpendk", "Orange Tsai"]
        }.merge!(instance_details)
        end

      end
    end


    module Task
      class MicrosoftExchangeCve202131207 < BaseCheck
        def self.check_metadata
          {
            allowed_types: ["Uri"],
            example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
            allowed_options: []
          }
        end

        def check
          # get enriched entity
          require_enrichment

          # affected versions
          vulnerable_versions = [
            # 2013
            { version: "2013", update: "Cumulative Update 23" },
          
            # 2016
            { version: "2016", update: "Cumulative Update 19" },
            { version: "2016", update: "Cumulative Update 20" },

            # 2019
            { version: "2019", update: "Cumulative Update 8" },
            { version: "2019", update: "Cumulative Update 9" },
          ]
  
          # get version for product
          version = get_version_for_vendor_product(@entity, 'Microsoft', 'Exchange Server')
          version_update = get_update_for_vendor_product(@entity, 'Microsoft', 'Exchange Server')
          return false unless version && version_update
  
          # if its vulnerable, return some proof
          if vulnerable_versions.include?({version: version, update: version_update})
            _log "Exchange server is vulnerable!"  
            return "Asset is vulnerable based on fingerprinted version #{version}:#{version_update}"
          end
        end

      end
    end

  end