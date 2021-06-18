module Intrigue
  module Task
    class SearchGrayhatWarfare < BaseTask
    
    def self.metadata
      {
        name: 'search_grayhat_warfare',
        pretty_name: 'Search Grayhat Warfare',
        authors: ['jcran', 'Anas Ben Salah'],
        description: 'This task hits the Grayhat Warfare API and finds buckets.',
        references: [],
        type: 'discovery',
        passive: true,
        allowed_types: ['DnsRecord', 'Domain', 'String', 'UniqueKeyword'],
        example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'intrigue.io' } }],
        allowed_options: [
          { name: 'max_buckets', regex: 'integer', default: 100 }
        ],
        created_types: ['AwsS3Bucket', 'AzureBlob']
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      # Make sure the key is set
      api_key = _get_task_config('grayhat_warfare_api_key')
      max_buckets = _get_option('max_buckets')

      search_string = _get_entity_name
      search_uri = "https://buckets.grayhatwarfare.com/api/v1/buckets/0/#{max_buckets}?access_token=#{api_key}&keywords=#{search_string}"

      begin

        # get it, make sure we don't have an empty response
        output = JSON.parse(http_get_body(search_uri))
        _log 'Unable to find any results.' unless output
        return unless output

        output['buckets'].each do |b|
          # {"id"=>1096, "bucket"=>"example.amazonaws.com", "fileCount"=>11, "type"=>"aws"}
          # {"id"=>137, "bucket"=>"abteststore.blob.core.windows.net", "fileCount"=>2, "type"=>"azure", "container"=>"files"}
          if b['type'] == 'aws'
            _create_entity 'AwsS3Bucket', {
              'name' => extract_bucket_name_from_url(b['bucket']),
              'bucket_uri' => "https://#{b["bucket"]}",
              'fileCount' =>  b['fileCount'],
            }
          elsif b['type'] == 'azure'
            _create_entity 'AzureBlob', {
              'name' => "https://#{b["bucket"]}",
              'uri' => "https://#{b["bucket"]}",
              'fileCount' =>  b['fileCount'],
              'type' =>  b['type']
            }
          else
            _log 'undefined storage type!'
          end
        end
      rescue JSON::ParserError => e
        _log_error "Unable to parse: #{e}"
      end
    end
    end
  end
end
