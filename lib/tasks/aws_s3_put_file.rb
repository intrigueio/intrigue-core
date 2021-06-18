module Intrigue
  module Task
    class AwsS3PutFile < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'aws_s3_put_file',
          pretty_name: 'AWS S3 Put File',
          authors: ['jcran', 'maxim'],
          description: 'This task verifies whether an S3 Bucket is publicly writeable.<br><br><b>Please note:</b> If the bucket belongs to the provided AWS Keys, the task will be stopped. This task is meant to test whether the bucket is writeable by other "authenticated" AWS users.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['AwsS3Bucket'],
          example_entities: [
            { 'type' => 'AwsS3Bucket', 'details' => { 'name' => 'test' } }
            # add additional keys option
          ],
          allowed_options: [],
          created_types: ['DnsRecord']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        region = bucket_enriched?
        return if region.nil?

        bucket_name = _get_entity_name

        s3_client = get_s3_client(bucket_name, region)
        return unless s3_client

        write_to_bucket(s3_client, bucket_name)
      end

      def get_s3_client(bucket_name, region)
        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        s3_client = initialize_s3_client(aws_access_key, aws_secret_key, region)
        s3_client = aws_key_valid?(s3_client, bucket_name) if s3_client

        _log_error 'AWS Keys are invalid; cannot proceed with task' unless s3_client

        if _get_entity_detail('belongs_to_api_key')
          _log 'Bucket belongs to API Key; skipping task as key may have permission to write to bucket.'
          return
        end

        s3_client
      end

      def bucket_enriched?
        require_enrichment if _get_entity_detail('region').nil?
        region = _get_entity_detail('region')
        _log_error 'Bucket does not have a region meaning it does not exist; exiting task.' if region.nil?
        region
      end

      def write_to_bucket(client, name)
        filename = SecureRandom.uuid
        begin
          client.put_object({ bucket: name, key: "#{filename}.txt" })
        rescue Aws::S3::Errors
          _log_error 'Permission denied; unable to upload file.'
          return
        end
        # no error? file uploaded successfully
        # maybe worth doing an additional check?
        _log_good 'Bucket is writable.'
        _create_linked_issue 'aws_s3_bucket_writable', {
          'proof' => "#{name}.s3.amazonaws.com/#{filename}.txt",
          'uri' => "#{name}.s3.amazonaws.com"
        }
      end

    end
  end
end
