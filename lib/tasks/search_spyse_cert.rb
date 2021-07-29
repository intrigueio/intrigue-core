module Intrigue
  module Task
    class SearchSpyseCert < BaseTask

      def self.metadata
        {
          name: 'search_spyse_cert',
          pretty_name: 'Search Spyse Cert',
          authors: ['Anas Ben Salah'],
          description: 'This task hits Spyse API for discovering domains registered with the same certificate',
          references: ['https://spyse-dev.readme.io/'],
          type: 'discovery',
          passive: true,
          allowed_types: ['SslCertificate'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: ['DnsRecord', 'Organization']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        # Get entity name
        ssl_certificate = _get_entity_name

        # Make sure the key is set
        api_key = _get_task_config('spyse_api_key')
        # Set the headers
        headers = { 'Accept' => 'application/json', 'Authorization' => "Bearer #{api_key}" }

        # Set the headers
        url = "https://api.spyse.com/v4/data/certificate/#{ssl_certificate}"

        # make the request
        response = http_request(:get, url, nil, headers)

        # Check response code status
        if response.code.to_i == 200
          # Parse json response
          json = JSON.parse(response.body)

          ## Create entities
          if json['data']['items']
            json['data']['items'].each do |result|
              # Check whether it is a wildcard certificate or not
              if (result['parsed']['names']).count > 1
                # Extract list of domains sharing the same certificate
                list_of_domains_sharing_same_certificate = result['parsed']['names']
                # Extarct certificate experation date
                end_date = result['parsed']['validity']['end']
                # Extract certificate algorithm
                algorithm = result['parsed']['signature_algorithm']['name']
                # Extract certificate serial number
                serial = result['parsed']['serial_number']
                # Create entity with spyse data
                _create_entity('SslCertificate', {
                  'name' => ssl_certificate,
                  'not_after' => end_date,
                  'serial' => serial,
                  'algorithm' => algorithm,
                  'list_of_domains_sharing_same_certificate' => list_of_domains_sharing_same_certificate
                })
              end

              # Create DnsRecord from domains registered with same certificate
              if result['parsed']['names']
                result['parsed']['names'].each do |domain|
                  _create_entity('DnsRecord', { 'name' => domain })
                end
              end
              # Create organizations related to the certificate
              if result['parsed']['subject']['organization']
                result['parsed']['subject']['organization'].each do |organization|
                  _create_entity('Organization', { 'name' => organization })
                end
              end
            end
          end
        else
          _log_error "unable to fetch response => error code: #{response.code}!"
        end
      end
    end
  end
end
