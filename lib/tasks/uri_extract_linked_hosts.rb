module Intrigue
  module Task
    class UriExtractLinkedHosts < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'uri_extract_linked_hosts',
          pretty_name: 'URI Extract Linked Hosts',
          authors: ['jcran'],
          description: 'This task analyzes and extracts hosts from links.',
          references: [],
          type: 'discovery',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'https://intrigue.io' } }
          ],
          allowed_options: [
            { name: 'extract_patterns', regex: 'alpha_numeric_list', default: 'default' }
          ],
          created_types: ['DnsRecord']
        }
      end

      def run
        super

        # Go collect the page's contents
        uri = _get_entity_name
        contents = http_get_body(uri)

        # default to our name for the extract pattern
        extract_patterns = return_extract_patterns

        unless contents
          _log_error "Unable to retrieve uri: #{uri}"
          return
        end

        ###
        ## Parse out s3,azure,gcloud buckets
        ###
        URI.extract(contents).each { |s| parse_bucket(s) }

        ###
        ### Now, parse out all links and do analysis on
        ### the individual links
        ###
        out = parse_dns_records_from_content(uri, contents.gsub(/%2f/i, ''), extract_patterns)
        out.each { |d| create_dns_entity_from_string(d['name'], nil, false, d) }
      end

      def return_extract_patterns
        return [] if _get_option('extract_patterns') == 'default'

        _get_option('extract_patterns').split(',')
      end

      def parse_bucket(uri_str)

        case uri_str
        when /s3\.amazonaws\.com/i
          name = extract_aws_bucket_name_from_string(uri_str)
          b = { 'type' => 'AwsS3Bucket', 'name' => name, 'uri' => "https://#{name}.s3.amazonaws.com" } if name
        when /storage\.googleapis\.com/i
          name = extract_gcp_bucket_name_from_string(uri_str)
          b = { 'type' => 'GcpBucket', 'name' => name, 'uri' => "https://storage.googleapis.com/#{name}" } if name
        when /blob\.core\.windows\.net/
          # name = extract_azure_blob_name_from_string(uri_str)
          # b = { 'type' => '', 'name' => name, 'uri' => "https://storage.googleapis.com/#{name}" } if name
          'test'
        end

        create_bucket_entity(b) unless b.nil?
      end

      def create_bucket_entity(bucket)
        _create_entity bucket['type'], {
          'name' => bucket['name'],
          'bucket_name' => bucket['name'],
          'bucket_uri' => bucket['uri']
        }
      end


    end
  end
end
