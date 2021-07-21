module Intrigue
  module Task
    class Wso2CarbonDefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::BruteForceLoginHelper
      require 'uri'

      def self.metadata
        {
          name: 'vuln/bruteforce/wso2_carbon_login_vuln',
          pretty_name: 'Bruteforce - WSO2 Carbon Default Login Credentials',
          authors: [''],
          description: 'Bruteforce WSO2 Carbon Default Login Credentials',
          type: 'Vuln',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'http://intrigue.io' } }
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
                                    'WSO2') && is_product?(fingerprint, 'Carbon') && tag?(fingerprint, 'Login Panel')

        credentials = [
          {
            user: 'admin',
            password: 'admin'
          }
        ]

        uri = URI(_get_entity_name)

        task_information = {
          http_method: :post,
          uri: "#{uri.scheme}://#{uri.host}/carbon/admin/login_action.jsp",
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
          data: {
          },
          follow_redirects: false,
          timeout: 10,
          thread_count: _get_option('threads'),
          uri_data: {
            base_uri: "#{uri.scheme}://#{uri.host}",
            token_uri: "#{uri.scheme}://#{uri.host}/carbon/admin/js/csrfPrevention.js"
          }
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
        response.code.to_i != 0 && !response.headers['Location'].match(/loginStatus=false/i)
      end

      def build_post_request(task_information, credential)
        headers = { "FETCH-CSRF-TOKEN": '1',
                    "Origin": task_information[:uri_data][:base_uri],
                    "Referer": "#{task_information[:uri_data][:base_uri]}/carbon/admin/login.jsp" }

        response = http_request :post, task_information[:uri_data][:token_uri], nil, headers

        return false unless response

        token = response.body_utf8.match(/X-CSRF-Token:([\w\d\-]+)/i)[1]

        unless token
          _log_debug 'Unable to retrieve CRFT token'
          return false
        end

        _log_debug "Fetched token: #{token}"

        task_information[:data] = {
          'username': credential[:user],
          'password': credential[:password],
          'X-CSRF-Token': token
        }

        true
      end
    end
  end
end
