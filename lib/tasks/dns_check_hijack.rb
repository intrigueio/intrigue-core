module Intrigue
  module Task
    class UriExtractEntities < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'dns_check_hijack',
          pretty_name: 'DNS Check Hijack',
          authors: ['jen140'],
          description: "This task checks if the domain or it's subdomains can be hijacked, contrary to the page content check in uri_check_subdomain_hijack this uses DNS responses.",
          references: [
            'https://github.com/EdOverflow/can-i-take-over-xyz',
            'https://github.com/projectdiscovery/nuclei-templates/blob/master/subdomain-takeover/detect-all-takeovers.yaml'
          ],
          allowed_types: ['Domain'],
          type: 'discovery',
          passive: true,
          example_entities: [{ 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: ['Domain']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        original_domain_name = _get_entity_name
        subdomain = original_domain_name
        have_cname = 0
        Resolv::DNS.open do |dns|
          loop do
            ress = dns.getresources subdomain, Resolv::DNS::Resource::IN::CNAME
            break if ress.empty?

            canonical_name = ress.first.name.to_s
            # _log_error "#{subdomain} is an alias for #{canonical_name}"
            subdomain = canonical_name
            have_cname = 1
          end
          ress = dns.getresources subdomain, Resolv::DNS::Resource::IN::A
          if ress.empty? && have_cname != 0
            if subdomain =~ /fastly/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /github.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /herokuapp/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /pantheonsite.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /domains.tumblr.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /wordpress.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /teamwork.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /helpjuice.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /helpscoutdocs.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /amazonaws/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /ghost.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /myshopify.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /uservoice.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /surge.sh/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /bitbucket.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /custom.intercom.help/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /proxy.webflow.com/ || subdomain =~ /proxy-ssl.webflow.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /wishpond.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /aftership.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /ideas.aha.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /domains.tictail.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /bcvp0rtal.com/ || subdomain =~ /brightcovegallery.com/ || subdomain =~ /gallery.video/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /bigcartel.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /createsend.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /acquia-test.co/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /simplebooklet.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /.gr8.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /vendecommerce.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /myjetbrains.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /.azurewebsites.net/ || subdomain =~ /.cloudapp.net/ || subdomain =~ /.cloudapp.azure.com/ || subdomain =~ /.trafficmanager.net/ || subdomain =~ /.blob.core.windows.net/ || subdomain =~ /.azure-api.net/ || subdomain =~ /.azurehdinsight.net/ || subdomain =~ /.azureedge.net/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /zendesk.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /readme.io/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /-portal.apigee.net/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            elsif subdomain =~ /domains.smugmug.com/
              _create_hijackable_subdomain_issue original_domain_name, subdomain
            end
          end
        end
      end

      def _create_hijackable_subdomain_issue(domain, subdomain)
        _create_linked_issue('subdomain_hijack', {
                               details: {
                                 domain: domain
                               },
                               proof: "Dangling subdomain: #{subdomain}"
                             })
      end
    end
  end
end
