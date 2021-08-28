module Intrigue
  module Task
    class PortainerDefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::BruteForceLoginHelper
      require 'uri'
      require 'json'

      def self.metadata
        {
          name: 'vuln/bruteforce/portainer_login_vuln',
          pretty_name: 'Bruteforce - Portainer Default Login Credentials',
          authors: [''],
          description: 'Bruteforce Portainer Default Login Credentials',
          type: 'Vuln',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'http://intrigue.io' } }
          ],
          affected_software: [
            {
              vendor: 'Portainer',
              product: 'Portainer'
            }
          ],
          allowed_options: [
            { name: 'threads', regex: 'integer', default: 10 }
          ],
          created_types: ['Uri']
        }
      end

      def run
        super
        require_enrichment

        fingerprint = _get_entity_detail('fingerprint')

        return false unless vendor?(fingerprint,
                                    'Portainer') && is_product?(fingerprint,
                                                                'Portainer') && tag?(fingerprint, 'Login Panel')

        # there is not default password for Portainer                                                        
        credentials = [
          {
            user: 'admin',
            password: 'admin'
          }
        ]

        uri = URI(_get_entity_name)
        base_uri = "#{uri.scheme}://#{uri.host}:#{uri.port}"

        task_information = {
          http_method: :post,
          uri: "#{base_uri}/api/auth",
          headers: { 'Content-Type' => 'application/json',
                     'Origin' => base_uri.to_s,
                     'Referer' => "#{base_uri}/" },
          data: {
          },
          follow_redirects: false,
          timeout: 10,
          thread_count: _get_option('threads')
        }

        # brute with force.
        brute_force_data = bruteforce_login(task_information, credentials, method(:validator),
                                            method(:build_post_request))

        unless brute_force_data[:credentials].empty?

          _log 'Creating issue'

          _create_linked_issue 'default_login_credentials',
                               {
                                 proof: {
                                   "Successful login credentials": brute_force_data[:credentials],
                                   "Responses": brute_force_data[:responses]
                                 }
                               }
        end
      end

      # custom validator, each default login task will have its own.
      # some tasks might require a more complex approach.
      def validator(response, task_information)
        !response.body_utf8.match(/"message":"Invalid credentials"/i)
      end

      def build_post_request(task_information, credential)

        task_information[:data] = {
          'username': credential[:user],
          'password': credential[:password],
        }.to_json

        true
      end
    end
  end
end
