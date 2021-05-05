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
          allowed_types: ['AwsCredential'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'AKIAOKZ52BOMZQ9WNUZ2:zc3w4zt5TU0/ItZ+OlzvaIdytJEz352fzH21ZonO9' } }],
          allowed_options: [
            { name: 'region', regex: 'alpha_numeric', default: 'us-east-1' }
          ],
          created_types: ['IpAddress']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        # Get the AWS Credentials
        aws_access_key = @entity.details['hidden_access_id']
        aws_secret_key = @entity.details['hidden_secret_key']
        aws_region = _get_option 'region'

        ec2 = Aws::EC2::Resource.new(region: aws_region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)

        begin
          instances = ec2.instances
          instances.first # force to authenticate to ensure creds are valid
        rescue Aws::EC2::Errors::AuthFailure
          _log_error 'Invalid AWS Keys.'
          nil
        rescue Aws::EC2::Errors::UnauthorizedOperation
          _log_error 'API Key lacks permission to list instances.'
          nil
        rescue Seahorse::Client::NetworkingError
          _log_error "Unable to connect to the AWS EC2 API, this is most likely because #{aws_region} is an invalid region."
          return nil
        end

        unless instances.count.positive?
          _log "No EC2 instances were discovered in #{aws_region}!"
          return nil
        end

        create_entities instances
      end

      def create_entities(ec2_instances)
        ec2_instances.each do |instance|
          _create_entity 'IpAddress', {
            'name' => instance.public_ip_address.nil? ? '0.0.0.0' : instance.public_ip_address,
            'region' => instance.placement.availability_zone.chop,
            'availability_zone' => instance.placement.availability_zone,
            'private_dns_name' => instance.private_dns_name,
            'private_ip_address' => instance.private_ip_address,
            'public_dns_name' => instance.public_ip_address
          }
        end
      end

    end
  end
end
