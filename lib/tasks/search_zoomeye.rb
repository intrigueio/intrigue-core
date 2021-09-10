module Intrigue
  module Task
    class SearchZoomEye < BaseTask
      def self.metadata
        {
          name: 'search_zoomeye',
          pretty_name: 'Search ZoomEye',
          authors: ['maxim'],
          description: 'Uses the ZoomEye API to search for information',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['IpAddress', 'NetBlock'],
          example_entities: [
            { 'type' => 'IpAddres', 'details' => { 'name' => '1.1.1.1' } }
          ],
          allowed_options: [],
          created_types: ['DnsRecord', 'IpAddress', 'NetworkService'],
          queue: 'task_scan'
        }

      end

      ## Default method, subclasses must override this
      def run
        super

        results_json = get_zoomeye_results
        _log_error 'Unable to obtain results from API call; aborting.' if results_json.nil?
        return if results_json.nil?

        results = parse_results(results_json)
        return if results.empty?

        _create_result_entities(results)
      end

      def parse_results(json_blob)
        # retrieve IP addresses
        final = []
        ips = json_blob.map { |r| r['ip'] }.uniq

        ips.each do |i|
          item = json_blob.select { |j| j['ip'] == i }
          ports = item.map { |z| z['portinfo']['port'] }
          hostnames = item.map { |z| z['portinfo']['rdns'] }.uniq.reject(&:empty?)
          final << { 'ip' => i, 'ports' => ports, 'hostnames' => hostnames }
        end

        _log 'No results found!' if final.empty?

        final
      end

      def get_zoomeye_results
        all_json = []

        response = make_zoomeye_api_call(1)
        return if response.nil?
        return if response['matches'].nil?

        all_json << response['matches'] # concat matches into array
        total_pages = (response['total'].to_i / 20.to_f).ceil # get amount of total pages rounded up

        return all_json.flatten if total_pages == 1 # only one page < 100 results; return

        # not multithreaded so rate limit is not reached
        pagination(total_pages, all_json) # array passed by reference so pagination will fill it in

        all_json.flatten.compact
      end

      def pagination(max_pages, output)
        (2..max_pages).each do |i|
          _log "Getting results from page #{i}"
          response = make_zoomeye_api_call(i)
          next if response.nil?
          next if response['matches'].nil?

          output << response['matches']
          sleep(1) # do not upset zoomeye
        end
      end

      def make_zoomeye_api_call(page)
        name = _get_entity_name
        api_key = _get_task_config('zoomeye_api_key')

        uri = "https://api.zoomeye.org/host/search?query=#{name}&page=#{page}"

        r = http_request(:get, uri, nil, { 'API-KEY' => api_key }, nil, true, 60).body
        _parse_json_response(r)
      end

      def _parse_json_response(response)
        JSON.parse(response)
      rescue JSON::ParserError
        _log_error 'Unable to parse JSON response; aborting.'
      end

      def _create_result_entities(results)
        results.each do |r|
          r['hostnames'].each { |h| create_dns_entity_from_string(h) } unless r['hostnames'].empty?
          e = _create_entity 'IpAddress', { 'name' => r['ip'] }
          r['ports'].each do |port|
            _create_network_service_entity(e, port, 'tcp')
          end
        end
      end
    end
  end
end
