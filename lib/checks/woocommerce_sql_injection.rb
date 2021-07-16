module Intrigue
  module Issue
    class WoocommerceSQLInjection < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-03-30',
          name: 'woocommerce_sql_injection',
          pretty_name: 'Woocommerce Unauthenticated SQL Injection',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'Pending Advisory Notes | WooCommerce (versions 3.3 through 5.5.0) and WooCommerce Blocks feature plugins (versions 2.5 through 5.5.0) were vulnerable to a critical unauthenticated SQL injection vulnerability.',
          identifiers: [
            { type: 'CVE', name: 'CVE-PENDING' }
          ],
          affected_software: [
            { vendor: 'WooCommerce', product: 'WooCommerce' }
          ],
          references: [
            { type: 'description', uri: 'https://woocommerce.com/posts/critical-vulnerability-detected-july-2021' },
            { type: 'description', uri: 'https://viblo.asia/p/phan-tich-loi-unauthen-sql-injection-woocommerce-naQZRQyQKvx' }
          ],

          # rootxharsh,iamnoooob,S1r1u5_,cookiehanhoan,madrobot
          authors: ['jl-dos', 'rootxharsh', 'iamnoooob', 'S1r1u5_', 'cookiehanhoan', 'madrobot', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class WoocommerceSQLInjection < BaseCheck
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
