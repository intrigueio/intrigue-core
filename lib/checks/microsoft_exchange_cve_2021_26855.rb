
module Intrigue

    module Issue
      class MicrosoftExchangeCve202126855 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-02",
          name: "microsoft_exchange_cve_2021_26855",
          pretty_name: "Mictosoft Exchange RCE (CVE-2021-26855)",
          identifiers: [{ type: "CVE", name: "CVE-2021-26855" }],
          severity: 1,
          status: "potential",
          category: "vulnerability",
          description: "Microsoft Exchange Server Remote Code Execution Vulnerability",
          remediation: "Install the latest security update for the specific product.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2013", :update => "Cumulative Update 23" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 18" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 19" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 7" },
            { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 8" }
          ],
          references: [
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
            
            require 'pry'; binding.pry
            if is_product?(fingerprint, "Exchange Server")
              if is_vulnerable_version?(fingerprint)
                  return true
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
        
                # 2013
                { version: "2013", update: "Cumulative Update 23" },
                
                # 2016
                { version: "2016", update: "Cumulative Update 18" },
                { version: "2016", update: "Cumulative Update 19" },
        
                # 2019
                { version: "2019", update: "Cumulative Update 7" },
                { version: "2019", update: "Cumulative Update 8" },
            ]
        end
  
      end
    end
  
  end