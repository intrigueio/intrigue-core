module Intrigue
  module Task
    module Enrich
      class AwsEC2Instance < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/aws_ec2_instance',
            pretty_name: 'Enrich AwsEC2Instance',
            authors: ['maxim'],
            description: 'Resolves an AWS EC2 instance.',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['AwsEC2Instance'],
            example_entities: [
              { 'type' => 'AwsEC2Instance', 'details' => { 'name' => 'ec2-13-132-97-113.us-east-2.compute.amazonaws.com' } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          _log "Enriching... AWS EC2 Instance: #{_get_entity_name}"

          public_hostname = _get_entity_detail('public_dns_name')
          private_hostname = _get_entity_detail('private_dns_name')
          # no point in having public ip address since DNSRecord enrichment will create it
          private_ip_address = _get_entity_detail('private_ip_address')

          _create_entity 'DNSRecord', 'name' => public_hostname unless public_hostname.empty? || public_hostname.nil?
          # private ipv4 hostname/address cannot be removed so no need for empty check
          _create_entity 'DNSRecord', 'name' => private_hostname unless private_hostname.empty? || private_hostname.nil?
          _create_entity 'IpAddress', 'name' => private_ip_address unless private_ip_address.empty || private_ip_address.nil?

        end

      end
    end
  end
end
