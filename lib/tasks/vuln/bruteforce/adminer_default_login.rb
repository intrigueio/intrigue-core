module Intrigue
  module Task
    class AdminerDefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::BruteForceLoginHelper
      require 'uri'
      require 'json'

      def self.metadata
        {
          name: 'vuln/bruteforce/adminer_login_vuln',
          pretty_name: 'Bruteforce - Adminer Default Login Credentials',
          authors: [''],
          description: 'Bruteforce Adminer Default Login Credentials',
          type: 'Vuln',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'http://intrigue.io' } }
          ],
          affected_software: [
            {
              vendor: 'Adminer',
              product: 'Adminer'
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
                                    'Adminer') && is_product?(fingerprint,
                                                              'Adminer') && tag?(fingerprint, 'Login Panel')

        credentials = [
          {
            user: 'adminer',
            password: ''
          }
        ]

        uri = URI(_get_entity_name)
        base_uri = "#{uri.scheme}://#{uri.host}:#{uri.port}"

        task_information = {
          http_method: :post,
          uri: "#{base_uri}/api/auth",
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                     'Host' => "#{uri.host}:#{uri.port}",
                     'Origin' => base_uri.to_s },
          data: {
            'auth[driver]' => 'server',
            'auth[auth]' => '',
            'auth[db]' => ''
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

        return false if response.code.to_s.empty? || response.code.to_i != 302

        # need to make a get request to ensure we can now login. Response needs to be != 403
        resp = http_request :get,
                            task_information[:uri],
                            nil,
                            task_information[:headers],
                            task_information[:data],
                            task_information[:follow_redirects],
                            task_information[:timeout]

        resp.code.to_i != 403 && !resp.body_utf8.match(/"Access denied for user"/i)
      end

      def build_post_request(task_information, credential)
        task_information[:uri] = "#{task_information[:headers]['Origin']}/?username=#{credential[:user]}"

        response = http_request :get, task_information[:uri]

        # get necessary information.
        adminer_key = response.headers['Set-Cookie'].to_s.match(/adminer_key=([\w\d\-]+);/i)[1]
        adminer_sid = response.headers['Set-Cookie'].to_s.match(/adminer_sid=([\w\d\-]+);/i)[1]
        adminer_version = response.body_utf8.to_s.match(/id="version">(\d+(\.\d+)*)/i)[1]

        # TODO - log this when failure happens to know which one failed.
        return false if adminer_key.nil? || adminer_sid.nil? || adminer_version.nil?

        _log_debug "Got adminer key: #{adminer_key} , Got adminer sid: #{adminer_sid} , Got adminer version: #{adminer_version}"

        task_information[:headers]['Cookie'] =
          "adminer_key=#{adminer_key}; adminer_version=#{adminer_version}; adminer_permanent=;adminer_sid=#{adminer_sid}"

        task_information[:headers]['Referer'] = "#{task_information[:headers]['Origin']}/?username=#{credential[:user]}"
        task_information[:data]['auth[username]'] = credential[:user]
        task_information[:data]['auth[password]'] = credential[:password]

        true
      end
    end
  end
end
