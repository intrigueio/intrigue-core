module Intrigue
    module Task
    class SonicwallCve20205135 < BaseTask
    
      def self.metadata
        {
          :name => "vuln/sonicwall_cve_2020_5135",
          :pretty_name => "Vuln Check - SonicWall (CVE-2020-5135)",
          :authors => ["shpendk","jcran"],
          :identifiers => [{ "cve" =>  "CVE-2020-5135" }],
          :description => "This task does a version check for CVE-2020-5135 in SonicWall SonicOS",
          :references => ["https://www.tenable.com/blog/cve-2020-5135-critical-sonicwall-vpn-portal-stack-based-buffer-overflow-vulnerability"],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["NetworkService"],
          :example_entities => [{"type" => "NetworkService", "details" => {"name" => "snmp://intrigue.io:161"}}],
          :created_types => []
        }
      end
    
      ## Default method, subclasses must override this
      def run
        super
    
        # first, ensure we're fingerprinted
        require_enrichment
        fingerprint = _get_entity_detail("fingerprint")

        if is_product?(fingerprint, "SonicOS")
          
          # get the fingerprints
          fp = fingerprint.select{|v| v['product'] == "SonicOS" }.first
          return "No fingerprint found for the product in question" unless fp
          
          if is_vulnerable_version?(fp)
            _create_linked_issue("sonicwall_cve_2020_5135", {
              proof: {
                detected_version: fp["version"]
              }
            })
          end
        end
      end
    
      def is_vulnerable_version?(fp)
        # affected: SonicOS 6.5.4.7-79n and below, fixed: SonicOS 6.5.4.7-83n
        # affected: SonicOS 6.5.1.11 and below, fixed: SonicOS 6.5.1.12-1n
        # affected: SonicOS 6.0.5.3-93o and below, fixed: SonicOS 6.0.5.3-94o
        # affected: SonicOSv 6.5.4.4-44v-21-794, fixed: SonicOS 6.5.4.v-21s-987
        # affected: SonicOS 7.0.0.0-1, fixed: SonicOS 7.0.0.0-2 and above
        
        # split version to retrieve major/minor versions
        version_parts = fp["version"].split(".")
        
        # check major version
        case version_parts[0].to_i
        when 0..5
            # "Major version is less than 6. We will automatically assume this is vulnerable"
            _log "Vulnerable!"
            _create_linked_issue("sonicwall_cve_2020_5135", {
                proof: {
                  detected_version: fp["version"]
                }
            })
        when 6
            # Hardest major version to handle
            check_vuln_version_six(version_parts[1],version_parts[2],version_parts[3])
        when 7
            check_vuln_version_seven(version_parts[1],version_parts[2],version_parts[3])
        else
            _log "Not vulnerable."
        end
        
      end


      def check_vuln_version_six(major, minor, micro)
        # for version 6, we have 4 cases
        # when 6.0 -> check further
        # when 6.1 - 6.4 -> assume vulnerable
        # when 6.5 -> check further
        # else not vulnerable

        # run cases
        case major.to_i 
            when 0 #handling case 6.0: if its 6.0.5.3 -> check after dash and confirm. If below, vuln, if above, not vuln
                check_vuln_version_six_zero(minor, micro)
            when 1..4
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            when 5 
                # handling various cases when version is 6.5
                check_vuln_version_six_five(minor, micro)
            else
                _log "Not Vulnerable."
        end
    end


      def check_vuln_version_seven(major, minor, micro)
        # version 7.0.0.0-1 and below are vulnerable
        dash = micro.split("-")
        before_dash = dash[0]
        after_dash = dash[1]

        
        if major.to_i == 0 and minor.to_i == 0 and before_dash.to_i == 0
            v = after_dash.to_i
            if v < 2
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            else
                _log "Not Vulnerable."
            end
        else
            _log "Not Vulnerable."
        end
    end

    def check_vuln_version_six_zero(minor, micro)
        # when version is 6.0.something, we have the following cases
        # 0-4 are vulnerable
        # 5.0 - 5.2 vulnerable
        # 5.3 must check micro part
        # else not vulnerable

        # split micro , since it may contain dash
        dash = micro.split("-")
        before_dash = dash[0]
        after_dash = dash[1]
        
        case minor.to_i
        when 0..4 
            _log "Vulnerable!"
            _create_linked_issue("sonicwall_cve_2020_5135", {
                proof: {
                  detected_version: fp["version"]
                }
            })
        when 5
            case before_dash.to_i
            when 0..2
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            when 3
                v = after_dash.to_i
                if v < 94
                    _log "Vulnerable!"
                    _create_linked_issue("sonicwall_cve_2020_5135", {
                        proof: {
                          detected_version: fp["version"]
                        }
                    })
                else
                    _log "Not Vulnerable."
                end
            else
                _log "Not Vulnerable."
            end
        else
            _log "Not vulnerable."
        end
    end

    def check_vuln_version_six_five(minor, micro)
        # when version is 6.5.something, we have the following cases
        # 0 -> vulnerable
        # 1 -> check micro
        # 2-3 -> vulnerable
        # 4 -> check micro
        # else not vulnerable

        # split micro , since it may contain dash
        dash = micro.split("-")
        before_dash = dash[0]
        after_dash = dash[1]

        case minor.to_i
        when 0
            _log "Vulnerable!"
            _create_linked_issue("sonicwall_cve_2020_5135", {
                proof: {
                  detected_version: fp["version"]
                }
            })
        when 1
            if before_dash.to_i < 12
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            else
                _log "Not Vulnerable."
            end 
        when 2..3
            _log "Vulnerable!"
            _create_linked_issue("sonicwall_cve_2020_5135", {
                proof: {
                  detected_version: fp["version"]
                }
            })
        when 4
            case before_dash.to_i
            when 0..3
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            when 4
                v = after_dash.to_i
                if v < 44
                    _log "Vulnerable!"
                    _create_linked_issue("sonicwall_cve_2020_5135", {
                        proof: {
                          detected_version: fp["version"]
                        }
                    })
                else
                    _log "Not Vulnerable."
                end
            when 5..6
                _log "Vulnerable!"
                _create_linked_issue("sonicwall_cve_2020_5135", {
                    proof: {
                      detected_version: fp["version"]
                    }
                })
            when 7
                v = after_dash.to_i
                if v < 83
                    _log "Vulnerable!"
                    _create_linked_issue("sonicwall_cve_2020_5135", {
                        proof: {
                          detected_version: fp["version"]
                        }
                    })
                else
                    _log "Not Vulnerable."
                end
            else
                _log "Not Vulnerable."
            end
        else 
            _log "Not Vulnerable."
        end
    
    end


    end
    end
    end
    