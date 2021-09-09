module Intrigue
  module Task
    class AwsS3Brute < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'aws_s3_bruteforce_buckets',
          pretty_name: 'AWS S3 Bruteforce Buckets',
          authors: ['jcran', 'maxim'],
          description: 'This task takes any keywords (including domains) and uses them to create permutations which are then bruteforced to confirm if a bucket with that name exists.<br><br>Task Options:<br><ul><li>additional_permutation_wordlist - (default value: empty) - Additional strings to use as a wordlist to generate permutations.</li><li>additional_keywords - (default value: false) - Additional keywords that can be used to generate bucket names with.</ul>',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['DnsRecord', 'Domain', 'IpAddress', 'Organization', 'String'],
          example_entities: [
            { 'type' => 'String', 'details' => { 'name' => 'test' } }
          ],
          allowed_options: [
            { name: 'additional_permutation_wordlist', regex: 'alpha_numeric_list', default: '' },
            { name: 'additional_keywords', regex: 'alpha_numeric_list', default: '' } # these can only be alphanumerical due to regex
          ],
          created_types: ['AwsS3Bucket']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        # create permutations
        additional_keywords = _get_option('additional_keywords').delete(' ').split(',')
        additional_keywords << _get_entity_name

        permutations = additional_keywords.map { |k| generate_permutations(k) } # generate permutations
        permutations << additional_keywords
        permutations.flatten!

        valid_buckets = bruteforce_buckets(permutations)
        _log "Found #{valid_buckets.size} valid buckets."
        return if valid_buckets.empty?

        valid_buckets.each { |v| create_entity(v) }
      end

      # generate permutations using the keywords provided along with the additional permutations wordlist
      def generate_permutations(keyword)
        _log "Generating permutations for keyword: #{keyword}"

        permutations = []
        patterns = ['.', '-', '']
        additional_permutations = _get_option('additional_permutation_wordlist').delete(' ').split(',') 

        words = ['backup', 'backups', 'dev', 'development', 'eng', 'engineering', 'old', 'prod', 'qa', 'stage', 'staging', 'test', 'testing', 'marketing', 'web']
        words << additional_permutations
        words.flatten!.uniq!

        # generate different sets of permutations
        patterns.each do |pattern|
          words.each do |word|
            permutations << "#{keyword}#{pattern}#{word}"
            permutations << "#{word}#{pattern}#{keyword}"
          end
        end

        permutations
      end

      def bruteforce_buckets(wordlist)
        buckets = []
        workers = (0...20).map do
          check = bucket_exists?(wordlist, buckets)
          [check]
        end
        workers.flatten.map(&:join)
        buckets
      end

      # confirm the bucket exists by extracting the region from the response headers
      def bucket_exists?(input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while bucket = input_q.shift
              region = http_request(:get, "https://#{bucket}.s3.amazonaws.com/").headers['x-amz-bucket-region']
              output_q << bucket if region
            end
          end
        end
        t
      end

      def create_entity(bucket)
        _create_entity 'AwsS3Bucket', {
          'name' => bucket, # use the new virtual host path since path style will be deprecated,
          'bucket_name' => bucket,
          'bucket_uri' => "#{bucket}.s3.amazonaws.com"
        }
      end

    end
  end
end