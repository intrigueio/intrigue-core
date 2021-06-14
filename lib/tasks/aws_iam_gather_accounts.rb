module Intrigue
  module Task
    class AwsIamGatherAccounts < BaseTask
      def self.metadata
        {
          name: 'aws_iam_gather_accounts',
          pretty_name: 'AWS IAM Gather Accounts',
          authors: ['jcran', 'maxim'],
          description: 'This task enumerates users and groups in AWS.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['String'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }],
          allowed_options: [],
          created_types: ['AwsIamAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        # IAM is global so region is not needed
        iam = Aws::IAM::Client.new({ region: 'us-east-1', access_key_id: aws_access_key, secret_access_key: aws_secret_key })

        begin
          groups = iam.list_groups
          users = iam.list_users
        rescue Aws::IAM::Errors::InvalidClientTokenId
          _log_error 'Invalid Access Key ID.'
          return nil
        rescue Aws::IAM::Errors::SignatureDoesNotMatch
          _log_error 'Secret Access Key does not match Access Key ID.'
          return nil
        rescue Aws::IAM::Errors::AccessDenied
          _log_error 'API Key lacks permission to list groups and/or users. Ensure both the ListGroups and ListUsers permissions are set.'
          return nil
        end

        create_group_entities groups
        create_user_entities users
      end

      def create_group_entities(group_list)
        group_list['groups'].each do |group|
          group_name = group.group_name
          _log "Retrieved the following group: #{group_name}"

          _create_entity 'AwsIamAccount', {
            'account_type' => 'group',
            'name' => "group/#{group_name}",
            'organization' => group.arn.split(':')[4],
            'arn' => group.arn,
            'id' => group.group_id
          }
        end
      end

      def create_user_entities(user_list)
        user_list['users'].each do |user|
          username = user.user_name
          _log "Retrieved the following user: #{username}"

          _create_entity 'AwsIamAccount', {
            'account_type' => 'user',
            'name' => "user/#{username}",
            'path' => user.path,
            'organization' => user.arn.split(':')[4],
            'arn' => user.arn,
            'id' => user.user_id,
            'created_at' => user.create_date
          }
        end
      end

    end
  end
end