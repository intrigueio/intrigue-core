module Intrigue
  module Task
    class AwsEc2GatherInstances < BaseTask
      def self.metadata
        {
          name: 'aws_ec2_gather_instances',
          pretty_name: 'AWS EC2 Gather Instances',
          authors: ['jcran', 'maxim'],
          description: 'This task enumerates machines running under an (authenticated) EC2 account.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'AwsCredential'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }],
          allowed_options: [
            { name: 'region', regex: 'alpha_numeric', default: 'changeme-region' }
          ],
          created_types: ['IpAddress']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        # Get the AWS Credentials
        aws_keys = get_aws_keys_from_entity_type(_get_entity_type_string)
        return unless aws_keys.access_key && aws_keys.secret_key

        return unless aws_keys_valid?(aws_keys.access_key, aws_keys.secret_key, aws_keys.session_token)

        regions = retrieve_region_list
        instance_collection = regions.map do |r|
          retrieve_instances(r, aws_keys.access_key, aws_keys.secret_key, aws_keys.session_token)
        end

        instance_collection.compact!
        return if instance_collection.size.zero?

        create_ec2_instances(instance_collection)
      end

      def retrieve_instances(region, access_key, secret_key, session_token)
        ec2 = Aws::EC2::Resource.new(region: region, access_key_id: access_key,
                                     secret_access_key: secret_key, session_token: session_token)

        begin
          instances = ec2.instances
          instances.first # force to authenticate to ensure creds are valid
        rescue Aws::EC2::Errors::UnauthorizedOperation
          _log_error "API Key lacks permission to list instances in #{region}"
          return nil
        rescue Seahorse::Client::NetworkingError
          _log_error "Unable to connect to the AWS EC2 API, this is most likely because #{region} is an invalid region."
          return nil
        end

        sleep(1) # dont upset aws
        _log "Found #{instances.count} instances in #{region}!"
        instances
      end

      def retrieve_region_list
        regions = _get_option('region')
        return regions.split(',') if regions != 'changeme-region'

        keys = get_aws_keys_from_entity_type(_get_entity_type_string)
        retrieve_ec2_regions(keys.access_key, keys.secret_key, keys.session_token)
      end

      # need to test with ipv6
      def create_ec2_instances(ec2_instance_collection)
        ec2_instance_collection.reject! { |e| e.count.zero? } # filter out empty collections

        ec2_instance_collection.each do |collection|
          collection.each do |instance|
          _create_entity 'AwsEC2Instance', {
            'name' => instance.public_dns_name.empty? ? instance.private_dns_name : instance.public_dns_name,
            'region' => instance.placement.availability_zone.chop,
            'availability_zone' => instance.placement.availability_zone,
            'public_ip_address' => instance.public_ip_address,
            'private_dns_name' => instance.private_dns_name,
            'private_ip_address' => instance.private_ip_address,
            'public_dns_name' => instance.public_dns_name
          }
          end
        end
      end

    end
  end
end