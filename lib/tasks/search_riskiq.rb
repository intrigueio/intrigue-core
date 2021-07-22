module Intrigue
  module Task
    class SearchRiskIQ < BaseTask
      def self.metadata
        {
          name: 'search_riskiq',
          pretty_name: 'Search RiskIQ',
          authors: ['Xiao-Lei Xiao'],
          description: 'This task utilises the service, RiskIQ to detect phishing, fraud, malware, and other online security threats. ',
          references: ['https://www.riskiq.com/'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain', 'IpAddress'],
          example_entities: [
            { 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } },
            { 'type' => 'IpAddress', 'details' => { 'name' => '1.1.1.1' } }
          ],
          allowed_options: [],
          created_types: ['DnsRecord', 'SslCertificate']
        }
      end

      def run
        super
        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        if entity_type == 'IpAddress'
          do_riskiq('address', entity_name)
        elsif entity_type == 'Domain'
          do_riskiq('domain', entity_name)
        else
          _log_error 'Unsupported entity type'
        end
      end

      def get_encoded_api_key
        api_key = _get_task_config 'riskiq_api_key'
        api_secret = _get_task_config 'riskiq_api_secret'
        "Basic #{Base64.strict_encode64("#{api_key}:#{api_secret}")}"
      end

      def do_domains(type, query)
        whois_api_url = "https://api.riskiq.net/v0/whois/#{type}?#{type}=#{query}&exact=false"

        _log 'Retrieving Domains...'

        domains_response = http_request(:get, whois_api_url, nil, {
                                          'Authorization' => get_encoded_api_key
                                        }, {}, true, 300)

        if domains_response.response_code == 504
          _log_error 'Domains Request timed out. Try again later.'
          return
        end

        domains_response_json = JSON.parse(domains_response.body)

        if domains_response_json['results'] == 0
          _log "No DNS results found for #{query}"
          return
        end

        _log "Found #{domains_response_json['results']} result(s) for #{query}"

        _log 'Processing Domains...'

        domains_response_json['domains'].each do |result|
          nameservers = result['nameServers']
          next if nameservers.empty?

          nameservers.each do |ns|
            create_dns_entity_from_string(ns)
          end
        end
        _log "Created DNS Record entities"
      end

      def do_ssl_certificates(query)
        _log 'Retrieving SSL Certificates...'

        ssl_api_url = "https://api.riskiq.net/v1/ssl/cert/host?host=#{query}"

        ssl_response = http_request(:get, ssl_api_url, nil, {
                                      'Authorization' => get_encoded_api_key
                                    }, {}, true, 300)

        if ssl_response.response_code == 504
          _log_error 'SSL Certificates Request timed out. Try again later.'
          return
        end

        ssl_response_json = JSON.parse(ssl_response.body)

        _log "No SSL Certificates found for #{query}" unless ssl_response_json['content'].length > 0

        _log 'Processing SSL Certificates...'
        ssl_response_json['content'].each do |content|
          cert = content['cert']

          _create_entity('SslCertificate', {
                           'name' => content['cert']['id'],
                           'cert_type' => content['cert']['signatureAlgorithm'].to_s,
                           'issuer' => content['cert']['issuer'].to_s,
                           'not_before' => cert['notBefore'].to_s,
                           'not_after' => cert['notAfter'].to_s,
                           'serial' => content['cert']['serialNumber'].to_s,
                           'subject' => content['cert']['subject'].to_s
                         })
        end

        _log "Created SSL Certificate Entities"
      end

      def do_riskiq(type, query)
        do_domains(type, query)
        # Only enter here if entity_name is an IP address
        do_ssl_certificates(query) if type == 'address'

      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end
  end
end
