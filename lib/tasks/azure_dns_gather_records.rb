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
          allowed_types: ['AzureTenant'],
          example_entities: [],
          example_entity_placeholder: false,
          allowed_options: [
            { name: 'SubscriptionID', regex: 'alpha_numeric', default: '' },
            { name: 'ignore_private_zones', regex: 'boolean', default: true }
          ],
          created_types: ['DnsRecord', 'Mailserver', 'Nameserver']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
  
        tenant_id = _get_entity_sensitive_detail('azure_tenant_id')
        access_token = _request_azure_oauth_token(tenant_id)
        return if access_token.nil?

        azure_client = Client::Search::Azure::ApiClient.new(access_token)
        return if azure_client.key_invalid?

        records = fetch_dns_records(azure_client)
        return if records.empty?

        records.each do |record|
          create_dns_entity_from_string(record.name) if ['CNAME', 'A', 'AAAA', 'SRV'].include?(record.type)
        end
      end

      def fetch_dns_records(client)
        all_records = []

        dns_zones = _collect_dns_zones(client)
        return if dns_zones.nil?

        dns_zones.each do |zone|
          records = client.get_zone_records(zone.subscription, zone.resource_group, zone.name)
          _log "Found #{records.size} records for #{zone.name}"
          next if records.nil? || records.empty?

          all_records << records
        end

        all_records.flatten
      end

      def _collect_dns_zones(client)
        subscriptions = client.list_subscriptions.map(&:id)
        return if subscriptions.nil?

        zones = subscriptions.map { |s| client.list_dns_zones(s) }.flatten
        zones.reject! { |z| z.public == false } if _get_option('ignore_private_zones')

        zones
      end

    end
  end
end
