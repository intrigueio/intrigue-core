module Intrigue
  module Entity
    class GcpBucket < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GcpBucket',
          description: 'A GCP Bucket',
          user_creatable: true,
          example: 'bucket-name'
        }
      end

      def validate_entity
        # https://cloud.google.com/storage/docs/naming-buckets
        # similar to s3 however cannot start with goog
        gcp_bucket_regex = /(?=^.{3,222}$)(?!^goog)(?!^(\d+\.)+\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$)/
        name.match(gcp_bucket_regex)
      end

      def detail_string
        "File count: #{details['contents'].count}" if details['contents']
      end

      def enrichment_tasks
        ['enrich/gcp_bucket']
      end

      def scoped?(_conditions = {})
        return scoped unless scoped.nil?
        return true if allow_list || project.allow_list_entity?(self)
        return false if deny_list || project.deny_list_entity?(self)

        true # otherwise just default to true
      end
    end
  end
end
