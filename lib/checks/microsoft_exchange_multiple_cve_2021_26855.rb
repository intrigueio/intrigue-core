
module Intrigue

    module Issue
      class MicrosoftExchangeCve202126855 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-02",
          name: "microsoft_exchange_multiple_cve_2021_26855.rb",
          pretty_name: "Microsoft Exchange Multple RCE CVEs",
          identifiers: [
            { type: "CVE", name: "CVE-2021-26412" },
            { type: "CVE", name: "CVE-2021-26854" },
            { type: "CVE", name: "CVE-2021-26855" },
            { type: "CVE", name: "CVE-2021-26857" },
            { type: "CVE", name: "CVE-2021-26858" },
            { type: "CVE", name: "CVE-2021-27065" },
            { type: "CVE", name: "CVE-2021-27078" },
          ],
          severity: 1,
          status: "potential",
          category: "vulnerability",
          description: "A chain of multiple remote code execution vulnerabilities have been identified being exploited in the wild. The vulnerabilities affect on-premise MS exchange servers, and require the ability to make an untrusted connection port 443.",
          remediation: "Install the latest security update for the specific products or limit connection on port 443 to trusted sources.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2013", :update => "Cumulative Update 23" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 18" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 19" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 7" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 8" }
          ],
          references: [
            { type: "description", uri: "https://msrc-blog.microsoft.com/2021/03/02/multiple-security-updates-released-for-exchange-server/" },
            { type: "description", uri: "https://www.microsoft.com/security/blog/2021/03/02/hafnium-targeting-exchange-servers/"},
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-26855" },
            { type: "description", uri: "https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-26855" },
          ],
          authors: ["shpendk", "Volexity", "orange_8361", "MSTIC"]
        }.merge!(instance_details)
        end
  
      end
    end  
    
  
    module Task
      class MicrosoftExchangeCve202126855 < BaseCheck 
        def self.check_metadata
          {
            allowed_types: ["Uri"],
            example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
            allowed_options: []
          }
        end
  
        def check
            # first, ensure we're fingerprinted
            require_enrichment
            fingerprint = _get_entity_detail("fingerprint")

            if is_product?(fingerprint, "Exchange Server")
              if is_vulnerable_version?(fingerprint)
                  return true
              end
            end
        end

        def is_vulnerable_version?(fingerprint)
          vulnerable_versions = [
            # 2013
            { version: "2013", update: "Cumulative Update 23" },
            # 2016
            #{ version: "2016", update: "Cumulative Update 18" },
            { version: "2016", update: "Cumulative Update 19" },
            # 2019
            #{ version: "2019", update: "Cumulative Update 7" },
            { version: "2019", update: "Cumulative Update 8" },
          ]

          # get the fingerprint
          fp = fingerprint.select{|v| v['product'] == "Exchange Server" }.first
          return false unless fp

          # get the vulnerable version for fingerprint
          vv = vulnerable_versions.select{|v| v[:version] == fp["version"]}.first
          return false unless vv

          if compare_versions_by_operator(fp["update"], vv[:update], "<=")
            return true
          end
        end
      end
    end
  
  end