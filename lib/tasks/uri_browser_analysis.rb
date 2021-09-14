module Intrigue
  module Task
    module Enrich
      class UriBrowserAnalysis < BaseTask
        include Intrigue::Task::Browser

        def self.metadata
          {
            name: 'uri_browser_analysis',
            pretty_name: '',
            authors: ['jcran'],
            description: 'This task utilizes Chrome to request a Uri, profiling, ' +
              'screenshoting and analyzing the response. Superset of uri_screenshot',
            references: [],
            type: 'discovery',
            passive: false,
            allowed_types: ['ApiEndpoint','Uri'],
            example_entities: [
              { 'type' => 'Uri', 'details' => { 'name' => 'http://www.intrigue.io' } }
            ],
            allowed_options: [
              { name: 'create_s3_buckets', regex: 'boolean', default: true },
              { name: 'create_issues', regex: 'boolean', default: true },
              { name: 'create_endpoints', regex: 'boolean', default: false },
              { name: 'create_wsendpoints', regex: 'boolean', default: true }
            ],
            created_types: [],
            queue: 'task_browser'
          }
        end

        ## Default method, subclasses must override this
        def run
          super

          uri = _get_entity_name

          ###
          ### If deny_list or hidden, just return
          ###
          if @entity.hidden || @entity.deny_list
            _log "this is a hidden / denied endpoint, we're returning"
            return
          end

          ###
          ### Browser-based data grab
          ###
          browser_data_hash = capture_screenshot_and_requests(uri)
          if browser_data_hash.empty?
            _log 'empty hash, returning w/o setting details'
            return
          end

          # split out request hosts, and then verify them
          if _get_option('create_endpoints')

            # look for mixed content
            if uri.match(/^https/)
              _log "Since we're here (and https), checking for mixed content..."
              _check_requests_for_mixed_content(uri, browser_data_hash['extended_browser_requests'])
            end

            _log 'Checking for other oddities...'
            request_hosts = browser_data_hash['request_hosts']
            _check_request_hosts_for_suspicious_request(uri, request_hosts)
            _check_request_hosts_for_exernally_hosted_resources(uri, request_hosts)
          end

          ###
          ## Parse contents for s3 buckets
          ###

          # first check our urls
          if _get_option('create_s3_buckets')
            _log 'Checking for S3 Buckets'

            request_urls = browser_data_hash['extended_browser_request_urls']
            request_urls.each do |s|
              next unless extract_bucket_name_from_string(s)

              _log "Found S3 bucket: #{s}"
              _create_entity 'AwsS3Bucket', {
                'name' => extract_bucket_name_from_string(s),
                'bucket_name' => extract_bucket_name_from_string(s),
                'bucket_uri' => "#{extract_bucket_name_from_string(s)}.s3.amazonaws.com" # convert to virtual path style
              }
            end

            if page_capture = browser_data_hash['extended_browser_page_capture']
              page_capture.scan(/.+\.amazonaws\.com.+/).each do |s|
                next unless extract_bucket_name_from_string(s)

                _log "Found S3 bucket: #{s}"
                _create_entity 'AwsS3Bucket', {
                  'name' => extract_bucket_name_from_string(s),
                  'bucket_name' => extract_bucket_name_from_string(s),
                  'bucket_uri' => "#{extract_bucket_name_from_string(s)}.s3.amazonaws.com" # convert to virtual path style
                }
              end
            end
          end

          ###
          ### Capture api endpoints (going forward this should be triggered by an event)
          ###
          if _get_option('create_endpoints')
            _log 'Creating broswer endpoints'
            if browser_responses = browser_data_hash['extended_browser_responses']
              _log "Creating #{browser_responses.count} endpoints"
              browser_responses.each do |r|
                puts r.keys.to_s
                next unless (r['url']).to_s.match(/^http.*$/i)

                _create_entity 'Uri', 'name' => r['url']
              end
            else
              _log_error "Unable to create entities, missing 'extended_responses' detail"
            end
          else
            _log 'Skipping normal browser responses'
          end

          if _get_option('create_wsendpoints')
            if browser_responses = browser_data_hash['extended_browser_wsresponses']
              browser_responses.each do |r|
                next unless (r['uri']).to_s.match(/^http.*$/i)

                _create_entity('ApiEndpoint', { 'name' => r['url'] })
              end
            else
              _log_error "Unable to create entities, missing 'extended_responses' detail"
            end
          else
            _log 'Skipping webservice browser responses'
          end

          # now merge them together and set as the new details
          # _get_and_set_entity_details browser_data_hash
        end
      end
    end
  end
end
