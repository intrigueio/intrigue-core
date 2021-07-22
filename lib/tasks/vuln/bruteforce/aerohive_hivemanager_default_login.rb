module Intrigue
  module Task
    class AerohiveDefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::BruteForceLoginHelper
      require 'uri'

      def self.metadata
        {
          name: 'vuln/bruteforce/aerohive_hivemanager_login_vuln',
          pretty_name: 'Bruteforce - Aerohive HiveManager Default Login Credentials',
          authors: [''],
          description: 'Bruteforce Aerohive HiveManager Default Login Credentials',
          type: 'Vuln',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'http://intrigue.io' } }
          ],
          affected_software: [
            {
              vendor: 'Aerohive',
              product: 'HiveManager'
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
                                    'Aerohive') && is_product?(fingerprint,
                                                               'HiveManager') && tag?(fingerprint, 'Login Panel')

        credentials = [
          {
            user: 'admin',
            password: 'aerohive'
          }
        ]

        uri = URI(_get_entity_name)
        base_uri = "#{uri.scheme}://#{uri.host}"
        task_information = {
          http_method: :post,
          uri: "#{base_uri}/hm/authenticate.action",
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded', #this might require a JSESSIONID, not sure how to fetch that.
                     'Origin' => base_uri.to_s,
                     'Referer' => "#{base_uri}/hm/login.action" },
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
        !response.body_utf8.match(/The login information you entered does not match an account on record. Please try again./i)
      end

      def build_post_request(task_information, credential)

        task_information[:data] = {
          'userName': credential[:user],
          'password': credential[:password],
        }

        true
      end
    end
  end
end
