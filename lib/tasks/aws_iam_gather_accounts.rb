module Intrigue
  module Task
    class AwsIamGatherAccounts < BaseTask
      def self.metadata
        {
          name: 'aws_iam_gather_accounts',
          pretty_name: 'AWS IAM Gather Accounts',
          authors: ['jcran'],
          description: 'Given AWS creds, this task enumerates aws iam accounts.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['AwsCredential'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'intrigue' } }],
          allowed_options: [
            { name: 'region', regex: 'alpha_numeric', default: 'us-east-1' }
          ],
          created_types: ['AwsIamAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        # Get the AWS Credentials
        aws_access_key = @entity.details['hidden_access_id']
        aws_secret_key = @entity.details['hidden_secret_key']

        # Get the region
        aws_region = _get_option 'region'

        begin
          # Connect to AWS using fog ...
          # TODO... prob want to remove the fog dep
          connection = Fog::AWS::IAM.new({
                                           aws_access_key_id: aws_access_key,
                                           aws_secret_access_key: aws_secret_key,
                                           region: aws_region
                                         })

          # Create groups
          connection.groups.each do |g|
            groupname = g.arn.to_s.split(':')[5]
            _log "Got: #{groupname}"

            # Create the entity
            _create_entity 'AwsIamAccount', {
              'account_type' => 'group',
              'region' => aws_region,
              'name' => groupname,
              'organization' => g.arn.to_s.split(':')[4],
              'arn' => g.arn.to_s,
              'id' => g.id
            }
          end

          # Create Users
          connection.users.each do |u|
            username = u.arn.to_s.split(':')[5]
            _log "Got: #{username}"

            # Create the entity
            # TODO .. should be associated with a credential (for enrichment)
            _create_entity 'AwsIamAccount', {
              'account_type' => 'user',
              'name' => username,
              'region' => aws_region,
              'path' => u.path.to_s,
              'organization' => u.arn.to_s.split(':')[4],
              'arn' => u.arn.to_s,
              'id' => u.id,
              'created_at' => u.created_at.to_s
            }
          end
        rescue Fog::AWS::IAM::Error => e
          _log_error "Error: #{e}"
        end
      end
    end
  end
end
