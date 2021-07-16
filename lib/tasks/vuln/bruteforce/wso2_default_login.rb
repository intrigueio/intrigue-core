module Intrigue
  module Task
    class Wso2DefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::BruteForceLoginHelper
      require 'uri'

      def self.metadata
        {
          name: 'vuln/bruteforce/wso2_login_vuln',
          pretty_name: 'Bruteforce - WSO2 Default Login Credentials',
          authors: [''],
          description: 'Bruteforce WSO2 Default Login Credentials',
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
        brute_force_data = bruteforce_login_post(task_information, credentials, method(:validator))

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

      def build_post_request_body(task_information, credential)
        headers = { "FETCH-CSRF-TOKEN": '1',
                    "Origin": task_information[:uri_data][:base_uri],
                    "Referer": "#{task_information[:uri_data][:base_uri]}/carbon/admin/login.jsp" }

        response = http_request :post, task_information[:uri_data][:token_uri], nil, headers

        return nil unless response

        token = response.body_utf8.match(/X-CSRF-Token:([\w\d\-]+)/i)[1]

        unless token
          _log_debug 'Unable to retrieve CRFT token'
          return nil
        end

        _log_debug "Token: #{token}"

        {
          'username' => credential[:user],
          'password' => credential[:password],
          'X-CSRF-Token' => token
        }
      end

      def bruteforce_login_post(task_information, credentials, validator)
        work_q = build_work_queue_post(credentials)

        brute_force_data = execute_workers_post(task_information, validator, work_q)
      end

      def build_work_queue_post(credentials)
        # always get default creds
        _log_debug 'Getting default credentials'

        credentials |= get_default_login_creds_from_file

        work_q = Queue.new

        while credential = credentials.pop
          _log_debug "Adding credential to work queue: #{credential}"
          work_q << credential
        end

        work_q
      end

      def execute_workers_post(task_information, validator, work_q)
        out = {
          responses: [],
          credentials: []
        }

        workers = (0...task_information[:thread_count]).map do
          Thread.new do
            while credential = work_q.pop(true)

              task_information[:data] = build_post_request_body task_information, credential

              next unless task_information[:data]

              _log_debug task_information[:data]

              send_request_and_validate_post task_information, credential, validator, out
            end
          rescue ThreadError
          end
        end

        workers.each(&:join)

        out
      end

      def send_request_and_validate_post(task_information, credential, validator, out)
        _log "Attempting #{task_information[:uri]} with credentials #{credential}"

        response = http_request task_information[:http_method],
                                task_information[:uri],
                                nil,
                                task_information[:headers],
                                task_information[:data],
                                task_information[:follow_redirects],
                                task_information[:timeout]

        return true unless response

        # only return response if validation was successful, else return nil.
        if validator.call(response)
          _log_good "Login successful login on #{task_information[:uri]} using credentials: #{credential}!"

          out[:responses] << response.body_utf8
          out[:credentials] << credential
        else
          _log "Login failed on #{task_information[:uri]} using credentials: #{credential}."
        end
        true
      end

      def get_default_login_creds_from_file
        _log 'Using default list from data/bruteforce/default_login_creds.json'
        begin
          JSON.parse(File.read("#{$intrigue_basedir}/data/bruteforce/default_login_creds.json"),
                     symbolize_names: true)
        rescue StandardError => e
          _log_error "Couldn't load #{$intrigue_basedir}/data/bruteforce/default_login_creds.json"
          _log_debug e
          []
        end
      end

      # custom validator, each default login task will have its own.
      # some tasks might require a more complex approach.
      def validator(response)
        response.code.to_i != 0 && !response.headers['Location'].match(/loginStatus=false/i)
      end

    end
  end
end
