module Intrigue
  module Task
    class SearchSpyseCert < BaseTask

      def self.metadata
        {
          name: 'search_spyse_cert',
          pretty_name: 'Search Spyse Cert',
          authors: ['Anas Ben Salah'],
          description: 'This task hits Spyse API for discovring domains registered with the same certificate',
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
        entity_name = _get_entity_name

        # Make sure the key is set
        api_key = _get_task_config('spyse_api_key')
        # Set the headers
        headers = { 'Accept' => 'application/json', 'Authorization' => "Bearer #{api_key}" }

        # Set the headers
        url = "https://api.spyse.com/v4/data/certificate/#{entity_name}"

        # make the request
        response = http_get_body(url, nil, headers)
        json = JSON.parse(response)

        json["data"]["items"].each do |result|
          ## Create issues
          # Create an issue if many domains founded registered with same Certificate
          if result['parsed']['names']
            _create_linked_issue('wildcard_certificate', {
              proof: result['parsed']['names'],
              references: ['https://spyse.com/'],
              source:'Spyse',
              details: result['parsed']
            })
          end
          # Create an issue for expired certificate
          if result['parsed']['validity']
            if Date.parse("#{result['parsed']['validity']['end']}") < Date.today
              _create_linked_issue('invalid_certificate_expired', {
                proof: result['parsed']['validity'],
                references: ['https://spyse.com/'],
                source:'Spyse',
                details: result['parsed']['validity']
              })
            elsif (Date.today-Date.parse("#{result['parsed']['validity']['end']}")) < 30
              _create_linked_issue('invalid_certificate_almost_expired', {
                proof: result['parsed']['validity'],
                references: ['https://spyse.com/'],
                source:'Spyse',
                details: result['parsed']['validity']
              })
            else
              _log 'Valid certificate date!'
            end
          end

          ## Create entities
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
    end
  end
end
