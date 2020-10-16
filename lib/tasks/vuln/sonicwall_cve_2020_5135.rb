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
          if is_vulnerable_version?(fingerprint)
              _create_linked_issue("sonicwall_cve_2020_5135")
          end
        end
      end
    
      def is_vulnerable_version?(fingerprint)
        # affected: SonicOS 6.5.4.7-79n and below, fixed: SonicOS 6.5.4.7-83n
        # affected: SonicOS 6.5.1.11 and below, fixed: SonicOS 6.5.1.12-1n
        # affected: SonicOS 6.0.5.3-93o and below, fixed: SonicOS 6.0.5.3-94o
        # affected: SonicOSv 6.5.4.4-44v-21-794, fixed: SonicOS 6.5.4.v-21s-987
        # affected: SonicOS 7.0.0.0-1, fixed: SonicOS 7.0.0.0-2 and above

        # get the fingerprints
        fp = fingerprint.select{|v| v['product'] == "SonicOS" }.first
        return false unless fp

        # check if fp["version"] is vulnerable
        
        # split version to retrieve major/minor versions
        version_parts = fp["version"].split(".")
        
        # check major version
        case version_parts[0].to_i
        when 0..5
            # "Major version is less than 6. We will automatically assume this is vulnerable"
            _log "Vulnerable!"
            _create_linked_issue( "sonicwall_cve_2020_5135")
        when 6
            # Hardest major version to handle
            check_vuln_version_six(version_parts)
        when 7
            check_vuln_version_seven(version_parts)
        end
        
      end


      def check_vuln_version_six(parts)
        # if 6.5.4.7 -> check after dash
        # if 6.5.1.11 -> check below 6.5.1.12
        # if 6.0.5.3-93o -> below 6.0.5.3-94o
        # if 6.5.4.4-44v-21-794  -> below 6.5.4.4-44v-21-795
        case parts[1].to_i 
        when 0 #handling case 6.0: if its 6.0.5.3 -> check after dash and confirm. If below, vuln, if above, not vuln
            case parts[2].to_i
            when 0..4 
                _log "Vulnerable!"
                create_linked_issue( "sonicwall_cve_2020_5135")
            when 5
                case parts[3].to_i
                when 0..2
                    _log "Vulnerable!"
                    create_linked_issue( "sonicwall_cve_2020_5135")
                when 3
                    # check after dash
                    afterdash = parts[4].split("-")
                    v = afterdash[1].to_i
                    if v < 94
                        _log "Vulnerable!"
                        create_linked_issue( "sonicwall_cve_2020_5135")
                    else
                        _log "Not Vulnerable."
                    end
                else
                    _log "Not Vulnerable."
                end
            else
                _log "Not vulnerable."
            end
        when 5 # handling various cases when version is 6.5
            # TODO
            #case parts[2].to_i
            #when 
            #end
        end
      end
    
    end
    end
    end
    