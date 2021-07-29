module Intrigue
  module Task
    module Enrich
      class GcpBucket < Intrigue::Task::BaseTask
        
        def self.metadata
          {
            name: 'enrich/gcp_bucket',
            pretty_name: 'Enrich GCP Bucket',
            authors: ['maxim'],
            description: 'Fills in details for an AwsS3Bucket.',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['GcpBucket'],
            example_entities: [
              { 'type' => 'GcpBucket', 'details' => { 'name' => 'bucket-name' } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          # TODO bug fix: when entity is created from task; name detail is not stored
          bucket_name = _get_entity_detail('name') || _get_entity_detail('bucket_name')
          return unless bucket_exists?(bucket_name)
        end
 
        ## confirm the bucket exists by extracting the region from the response headers
        # clean this up as it borred for aws enrichment task
        def bucket_exists?(bucket_name)
          response_code = http_request(:get, "https://storage.googleapis.com/#{bucket_name}").code

          if response_code == '404'
            @entity.hidden = true # bucket is invalid; hide the entity
            @entity.save_changes
            _log_error 'Bucket returns a status code of 404 meaning it does not exist.'
            false
          else
            _log_good 'Bucket exists!'
            _set_entity_detail 'bucket_name', bucket_name 
            true
          end
        end


      end
    end
  end
end
