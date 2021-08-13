module Intrigue
  module Issue
    class WoocommerceCVE202132790 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-03-30',
          name: 'woocommerce_cve_2021_32790',
          pretty_name: 'Woocommerce Unauthenticated SQL Injection (CVE-2021-32790)',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'An SQL injection vulnerability impacts all WooCommerce sites running the WooCommerce plugin between version 3.3.0 and 3.3.6. Malicious actors (already) having admin access, or API keys to the WooCommerce site can exploit vulnerable endpoints of `/wp-json/wc/v3/webhooks`, `/wp-json/wc/v2/webhooks` and other webhook listing API. Read-only SQL queries can be executed using this exploit, while data will not be returned, by carefully crafting `search` parameter information can be disclosed using timing and related attacks.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2021-32790' }
          ],
          affected_software: [
            { vendor: 'WooCommerce', product: 'WooCommerce' }
          ],
          references: [
            { type: 'description', uri: 'https://woocommerce.com/posts/critical-vulnerability-detected-july-2021' },
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2021-32790'},
            { type: 'description', uri: 'https://viblo.asia/p/phan-tich-loi-unauthen-sql-injection-woocommerce-naQZRQyQKvx' }
          ],
          authors: ['jl-dos', 'rootxharsh', 'iamnoooob', 'S1r1u5_', 'cookiehanhoan', 'madrobot', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class WoocommerceCVE202132790 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        template = 'vulnerabilities/wordpress/wordpress-woocommerce-sqli'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end
