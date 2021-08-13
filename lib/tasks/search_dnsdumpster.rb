module Intrigue
  module Task
    class SearchDNSdumpster < BaseTask
      def self.metadata
        {
          name: 'search_dnsdumpster',
          pretty_name: 'Search DNSdumpster',
          authors: ['Xiao-Lei Xiao'],
          description: 'This task utilises the domain research tool DNSdumpster to research, find & lookup dns records. ',
          references: ['https://dnsdumpster.com/'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [
            { 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }
          ],
          allowed_options: [],
          created_types: ['Domain', 'DnsRecord']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        entity_name = _get_entity_name

        response = http_request(:get, 'https://dnsdumpster.com/', nil, {})
        cookie = response.headers['Set-Cookie'].match(/(.*?;){1}/)
        token = cookie.to_s.scan(/=(.+)[,;]$/)[0][0]

        response = http_request(:post, 'https://dnsdumpster.com/', nil, {
                                  'Referer' => 'https://dnsdumpster.com/',
                                  'Cookie' => cookie.to_s
                                }, "csrfmiddlewaretoken=#{token}&targetip=#{entity_name}", true, 300)

        if response.return_code == :operation_timedout
          _log_error 'Request timed out. Try again later.'
          return
        end

        doc = Nokogiri::HTML(response.body_utf8)
        table = doc.css('table')[0]

        if table.nil?
          _log_error "Could not find the DNS table for #{entity_name}"
          return
        end

        subdomains = doc.css('table')[0].search('tr').map { |tr| tr.content.delete!("\n").split(' ')[0] }
        
        _log_good "Found #{subdomains.length} subdomains for #{entity_name}"

        subdomains.each { |s| create_dns_entity_from_string(s) } unless subdomains.empty?
      end
    end
  end
end
