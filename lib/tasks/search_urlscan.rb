module Intrigue
  module Task
    class SearchUrlscan < BaseTask
      def self.metadata
        {
          name: 'search_urlscan',
          pretty_name: 'Search Urlscan',
          authors: ['Xiao-Lei Xiao'],
          description: 'This task utilises the free service, urlscan.io to scan and analyse websites',
          references: ['https://urlscan.io/'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [
            { 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }
          ],
          allowed_options: [],
          created_types: ['Domain', 'IpAddress', 'SslCertificate']
        }
      end

      def run
        super
        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        if entity_type == 'IpAddress'
          do_urlscan('ip', entity_name)
        elsif entity_type == 'Domain'
          do_urlscan('domain', entity_name)
        else
          _log_error 'Unsupported entity type'
        end
      end

      def do_scan(query)
        api_key = _get_task_config 'urlscan_api_key'

        scan_response = http_request(:post, 'https://urlscan.io/api/v1/scan/', nil,
                                     { 'Content-Type' => 'application/json', 'API-Key' => api_key }, { url: query, visibility: 'private' }.to_json)

        scan_json = JSON.parse(scan_response.body)

        _log scan_json['message']

        hasResults = false

        # Poll until we get results
        until hasResults
          _log "Polling from #{scan_json['api']}..."

          poll_response = http_request(:get, scan_json['api'], nil, {}, {})

          if poll_response.code == '200'
            hasResults = true
            _log_good 'Polling completed...Results found!'
          end

          sleep(10)
        end

        results_response = http_request(:get, scan_json['api'], nil, {}, {})
        results_json = JSON.parse(results_response.body)

        _log_good "Scan results received from #{scan_json['api']}!"

        results_json
      end

      def process_entities(json)
        _log 'Processing entities...'

        lists = json['lists']

        ips_list = lists['ips']
        domains_list = lists['domains']
        certificates_list = lists['certificates']

        _log 'Processing IPs...'
        _log 'No IPs found' unless ips_list.length > 0
        ips_list.each do |ip|
          _create_entity 'IpAddress', { name: ip }
        end
        _log "Processed #{ips_list.length} IPs"

        _log 'Processing Domains...'
        _log 'No Domains found' unless domains_list.length > 0
        domains_list.each do |domain|
          _create_entity('Domain', { name: domain })
        end
        _log "Processed #{domains_list.length} Domains"

        _log 'Processing Certificates...'
        _log 'No Certificates found' unless certificates_list.length > 0
        certificates_list.each do |certificate|
          _create_entity('SslCertificate', { name: certificate['subjectName'] })
        end
        _log "Processed #{certificates_list.length} Certificates"

        _log_good 'Processing entities complete!'
      end

      def do_urlscan(query_type, query)
        search_response = http_get_body("https://urlscan.io/api/v1/search/?q=#{query_type}:#{query}", nil, {})
        search_json = JSON.parse(search_response)

        results = search_json['results']
        matched_results = search_json['results'].filter do |_result|
          _result['page']['domain'] == query
        end

        # If there are no results or nothing matches with the query and query type, do a hit to the /scan endpoint
        if results.length == 0 || matched_results.length == 0
          _log "No search results found for #{query}"
          _log "Initiating scan for #{query}"
          results_json = do_scan(query)

          process_entities(results_json)
          return
        end

        result = matched_results[0]
        page = result['page']

        _log_good "Found a match for #{query} from search results!"

        match = result['result']

        match_response = http_request(:get, match, nil, {}, {})
        match_json = JSON.parse(match_response.body)

        process_entities(match_json)

      end
    end
  end
end
