
module Intrigue

    module Issue
      class ZyxelCve20199955 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "zyxel_cve_2019_9955",
          pretty_name: "Zyxel Reflected XSS (CVE-2019-9955)",
          severity: 3,
          category: "vulnerability",
          status: "confirmed",
          description: "On Zyxel ATP200, ATP500, ATP800, USG20-VPN, USG20W-VPN, USG40, USG40W, USG60, USG60W, USG110, USG210, USG310, USG1100, USG1900, USG2200-VPN, ZyWALL 110, ZyWALL 310, ZyWALL 1100 devices, the security firewall login page is vulnerable to Reflected XSS via the unsanitized 'mp_idx' parameter.",
          affected_software: [ 
            { :vendor => "Zyxel", :product => "ATP200" },
            { :vendor => "Zyxel", :product => "ATP500" },
            { :vendor => "Zyxel", :product => "ATP800" },
            { :vendor => "Zyxel", :product => "USG20-VPN" },
            { :vendor => "Zyxel", :product => "USG20W-VPN" },
            { :vendor => "Zyxel", :product => "USG40" },
            { :vendor => "Zyxel", :product => "USG40W" },
            { :vendor => "Zyxel", :product => "USG60" },
            { :vendor => "Zyxel", :product => "USG60W" },
            { :vendor => "Zyxel", :product => "USG110" },
            { :vendor => "Zyxel", :product => "USG210" },
            { :vendor => "Zyxel", :product => "USG310" },
            { :vendor => "Zyxel", :product => "USG1100" },
            { :vendor => "Zyxel", :product => "USG1900" },
            { :vendor => "Zyxel", :product => "USG2200-VPN" },
            { :vendor => "Zyxel", :product => "ZyWALL 110" },
            { :vendor => "Zyxel", :product => "ZyWALL 310" },
            { :vendor => "Zyxel", :product => "ZyWALL 1100" }
          ],
          identifiers: [
            { type: "CVE", name: "CVE-2019-9955" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-9955" },
            { type: "exploit", uri: "https://packetstormsecurity.com/files/152525/Zyxel-ZyWall-Cross-Site-Scripting.html" }
          ],
          authors: ["pd-team", "Aaron Bishop", "jen140"]
        }.merge!(instance_details)
        end
      end
    end

    module Task
      class ZyxelCve20199955 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-9955"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

      end
    end

    end 
