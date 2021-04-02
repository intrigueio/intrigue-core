
module Intrigue

    module Issue
      class DrupalCve20196340 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "drupal_cve_2019_6340",
          pretty_name: "Drupal RCE (CVE-2019-6340)",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "Some field types do not properly sanitize data from non-form sources in Drupal 8.5.x before 8.5.11 and Drupal 8.6.x before 8.6.10. This can lead to arbitrary PHP code execution in some cases. A site is only affected by this if one of the following conditions is met: The site has the Drupal 8 core RESTful Web Services (rest) module enabled and allows PATCH or POST requests, or the site has another web services module enabled, like JSON:API in Drupal 8, or Services or RESTful Web Services in Drupal 7. (Note: The Drupal 7 Services module itself does not require an update at this time, but you should apply other contributed updates associated with this advisory if Services is in use.)",
          affected_software: [ 
            { :vendor => "Drupal", :product => "Drupal" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-6340" },
            { type: "exploit", uri: "https://www.exploit-db.com/exploits/46459" }
          ],
          authors: ["madrobot", "LEONJZA", "jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class DrupalCve20196340 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-6340"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
