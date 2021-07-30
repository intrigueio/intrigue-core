module Intrigue
  module Task
    class SearchGrayhatWarfare < BaseTask
      def self.metadata
        {
          name: 'search_grayhat_warfare',
          pretty_name: 'Search Grayhat Warfare',
          authors: ['jcran', 'Anas Ben Salah', 'maxim'],
          description: 'This task hits the Grayhat Warfare API and finds buckets.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['DnsRecord', 'Domain', 'String', 'UniqueKeyword'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [
            { name: 'max_buckets', regex: 'integer', default: 100 }
          ],
          created_types: ['AwsS3Bucket', 'AzureStorageAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        search_uri = construct_api_call

        output = return_grayhat_response(search_uri)
        return if output.nil?

        _log_good "Obtained #{output.size} results!"
        iterate_results(output) unless output.empty?
      end

      def create_s3_bucket(s3)
        _create_entity 'AwsS3Bucket', {
          'name' => extract_bucket_name_from_string(s3['bucket']),
          'bucket_name' => extract_bucket_name_from_string(s3['bucket']),
          'bucket_uri' => "https://#{s3['bucket']}",
          'objects' => s3['fileCount']
        }
      end

      def create_azure_storage_account(azure)
        _create_entity 'AzureStorageAccount', {
          'name' => extract_storage_account_from_string(azure['bucket']),
          'storage_name' => extract_storage_account_from_string(azure['bucket']),
          'uri' => azure['bucket'],
          'fileCount' => azure['fileCount'],
          'containers' => [azure['container']]
        }
      end

      def iterate_results(results)
        results['buckets'].each do |b|
          case b['type']
          when 'aws'
            create_s3_bucket(b)
          when 'azure'
            create_azure_storage_account(b)
          end
        end
      end

      def return_grayhat_response(uri)
        JSON.parse(http_get_body(uri))
      rescue JSON::ParserError => e
        _log_error "Unable to parse: #{e}"
      end

      def construct_api_call
        api_key = _get_task_config('grayhat_warfare_api_key')
        max_buckets = _get_option('max_buckets')

        search_string = _get_entity_name
        "https://buckets.grayhatwarfare.com/api/v1/buckets/0/#{max_buckets}?access_token=#{api_key}&keywords=#{search_string}"
      end

    end
  end
end
