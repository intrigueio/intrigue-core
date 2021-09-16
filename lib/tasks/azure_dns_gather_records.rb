module Intrigue
  module Task
    class AzureDnsGatherRecords < BaseTask
      def self.metadata
        {
          name: 'azure_dns_gather_records',
          pretty_name: 'Azure DNS Gather Records',
          authors: ['maxim'],
          description: 'balbalablabalbala</b>',
          references: ['balbalablabl'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'AzureCredential'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }],
          example_entity_placeholder: false,
          allowed_options: [
            { name: 'SubscriptionID', regex: 'alpha_numeric', default: '' }
          ],
          created_types: ['DnsRecord', 'Mailserver', 'Nameserver']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        

        # verify oauth token is valid
        # either get subscription from entity options or pull all subscriptions
        # make request to pull dnszones
        access_token = 'abc'
        azure_client = Client::Search::Azure::ApiClient.new(access_token)
        require 'pry'; binding.pry


        subscriptions = azure_client.list_subscriptions.map(&:id)
        dns_zones = subscriptions.map { |s| azure_client.list_dns_zones(s) }.flatten

        zone = dns_zones.first

        records = azure_client.get_zone_records(zone.subscription, zone.resource_group, zone.name)

    

      end
    end
  end
end
