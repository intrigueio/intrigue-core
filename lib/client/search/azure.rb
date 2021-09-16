module Intrigue
  module Client
    module Search
      module Azure
        class ApiClient
          include Intrigue::Task::Web

          attr_accessor :service_name

          def initialize(key)
            @api_key = key
          end

          def key_invalid?
            _azure_api_call(:get, '/subscriptions?api-version=2014-04-01-preview').code == '401'
          end

          ## returns an array of structs populated with subscription data
          def list_subscriptions
            subscriptions = []

            r = _azure_api_call(:get, '/subscriptions?api-version=2014-04-01-preview').body
            parsed = _parse_json_response(r)

            return subscriptions if parsed['value'].nil? || parsed['value'].empty?

            parsed['value'].each do |sub|
              subscriptions << Struct.new(:name, :id).new(sub['displayName'], sub['subscriptionId'])
            end

            subscriptions
          end

          def list_dns_zones(subscription)
            zones = []
            dns_zone = Struct.new(:name, :subscription, :resource_group, :location, :public)

            r = _azure_api_call(:get, "/subscriptions/#{subscription}/providers/Microsoft.Network/dnszones?api-version=2018-05-01")
            parsed = _parse_json_response(r.body)

            parsed['value'].each do |zone|
              group = zone['id'].scan(%r{/resourceGroups/(.+)/providers}).flatten.first
              zones << dns_zone.new(zone['name'], subscription, group, zone['location'], zone['zoneType'].eql?('Public'))
            end

            zones
          end

          def get_zone_records(subscription, resource, name)
            records = []

            route = "/subscriptions/#{subscription}/resourceGroups/#{resource}/providers/Microsoft.Network/dnsZones/#{name}/all?api-version=2018-05-01"
            r = _azure_api_call(:get, route)
            parsed = _parse_json_response(r.body)

            return records if parsed.nil? || parsed['value'].empty?

            parsed['value'].each do |record|
              records << _parse_dns_record(record)
            end

            records
          end

          # check every response to see if access token expired?

          private

          def _azure_api_call(method, route)
            Typhoeus::Request.new(
              "https://management.azure.com#{route}",
              method: method,
              headers: { 'Authorization' => "Bearer #{@api_key}" }
            ).run
          end

          def _parse_json_response(response)
            JSON.parse(response)
          rescue JSON::ParserError
            _log_error 'Error parsing JSON response; aborting.'
          end

          def _parse_dns_record(record)
            record_struct = Struct.new(:type, :name, :value) # value not needed as core will resolve it when enriched as dnsrecord
            case record['type'].split('/')[2]
            when 'A'
              values = record['properties']['ARecords'].map(&:values).flatten
              record_struct.new('A', record['properties']['fqdn'], values)
            when 'CNAME'
              # fetch in case alias type which will return nil for CNAMERecord key
              # if alias record it will be resolved anyways so ignore it for now
              record_struct.new('CNAME', record['properties']['fqdn'], record['properties']&.fetch('CNAMERecord'))
            when 'NS'
              values = record['properties']['NSRecords'].map(&:values).flatten
              record_struct.new('NS', record['properties']['fqdn'], values)
            when 'SRV'
              record_struct.new('NS', record['properties']['fqdn'], record['properties']['SRVRecords'])
            when 'AAAA'
              values = record['properties']['AAAARecords'].map(&:values).flatten
              record_struct.new('NS', record['properties']['fqdn'], values)
            when 'MX'
              values = record['properties']['MXRecords'].map(&:values).flatten
              record_struct.new('MX', record['properties']['fqdn'], values)
            when 'SOA'
              record_struct.new('SOA', record['properties']['fqdn'], record['properties']['SOARecord'])
            when 'TXT'
              values = record['properties']['TXTRecords'].map(&:values).flatten
              record_struct.new('TXT', record['properties']['fqdn'], values)
            when 'CAA'
              record_struct.new('CAA', record['properties']['fqdn'], record['properties']['caaRecords'])
            end
          end
        end
      end
    end
  end
end
