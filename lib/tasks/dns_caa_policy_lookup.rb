module Intrigue
  module Task
    class DnsCaaPolicyLookup < BaseTask
      include Intrigue::Task::Dns

      def self.metadata
        {
          name: 'dns_caa_policy_lookup',
          pretty_name: 'DNS CAA Lookup',
          authors: ['jen140'],
          description: 'Look up the CAA records of the given DNS record.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [{ 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: %w[tag host]
        }
      end

      def run
        super

        domain_name = _get_entity_name

        _log "Running CAA lookup on #{domain_name}"

        res_answer = collect_caa_records domain_name

        # If we got a success to the query.
        if res_answer.count > 0
          valid_caa = false
          _log 'CAA found, validating'
          cert_issuer = Net::HTTP.start(domain_name, '443', use_ssl: true) do |http|
            http.peer_cert.issuer.to_a.select { |name, _, _| name == 'O' } # extract the organization
          end
          cert_issuer = if cert_issuer.any?
                          cert_issuer.first[1]
                        else
                          'main certificate is invalid'
                        end
          res_answer.each do |elem|
            next unless elem['tag'] == 'issue' || elem['tag'] == 'issuewild'

            caa_cert_issuer = Net::HTTP.start(elem['host'], '443', use_ssl: true) do |http|
              http.peer_cert.subject.to_a.select { |name, _, _| name == 'O' }
            end
            caa_cert_issuer = if caa_cert_issuer.any?
                                caa_cert_issuer.first[1]
                              else
                                'ca certificate is invalid'
                              end
            valid_caa = true if cert_issuer == caa_cert_issuer
          end
          if valid_caa != true
            _log 'Not a valid CAA on the domain!'
            _create_linked_issue('dns_caa_wrong_policy', {
                                   proof: 'Invalid CAA record',
                                   status: 'confirmed'
                                 })
          else
            _log 'CAA is valid'
          end
        else
          _log 'No CAA on the domain!'
          _create_linked_issue('dns_caa_policy_missing', {
                                 proof: 'No CAA record',
                                 status: 'confirmed'
                               })
        end
      end
    end
  end
end
