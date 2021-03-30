
module Intrigue

    module Issue
      class MicrosoftExchangeCve202126855 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-02",
          name: "microsoft_exchange_multiple_cve_2021_26855.rb",
          pretty_name: "Microsoft Exchange Multiple RCE CVEs (CVE-2021-26855)",
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
          status: "confirmed",
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

            { type: "exploit", uri: "https://www.exploit-db.com/exploits/49637" },
            { type: "exploit", uri: "https://www.praetorian.com/blog/reproducing-proxylogon-exploit/" },
            { type: "exploit", uri: "https://twitter.com/irsdl/status/1369811265707778052" },

            { type: "threat_intel", uri: "https://www.crowdstrike.com/blog/falcon-complete-stops-microsoft-exchange-server-zero-day-exploits/" },
            { type: "threat_intel", uri: "https://www.reddit.com/r/sysadmin/comments/lz1jp4/youve_been_hit_by_youve_been_struck_by_an/" },
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
          return {verified: "yes"}
            # check if we can perform SSRF
            uri = "#{_get_entity_name}"
            headers = {
              "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0",
              "Cookie" => "X-AnonResource=true; X-AnonResource-Backend=localhost/ecp/default.flt?~3; X-BEResource=localhost/owa/auth/logon.aspx?~3;"
            }
            
            res = http_request :get, uri, nil, headers
            if res.code.to_i == 500 && res.body_utf8 =~ /NegotiateSecurityContext/
              _log "Vulnerable! SSRF successful and this is a confirmed issue."
              return res.body_utf8
            end

            # if original URI didn't work, lets try the default url
            _log "Testing at /owa/auth/x.js"
            uri_obj = URI(uri)
            endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/owa/auth/x.js"
            res = http_request :get, endpoint, nil, headers
            if res.code.to_i == 500 && res.body_utf8 =~ /NegotiateSecurityContext/
              _log "Vulnerable! SSRF successful and this is a confirmed issue."
              return res.body_utf8
            end

            ################################################
            ### SSRF failed, fallback to version comparison
            ################################################

            # ensure we're fingerprinted
            require_enrichment
            fingerprint = _get_entity_detail("fingerprint")

            if is_product?(fingerprint, "Exchange Server")
              if is_vulnerable_version?(fingerprint)
                  return {status: "potential"}
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