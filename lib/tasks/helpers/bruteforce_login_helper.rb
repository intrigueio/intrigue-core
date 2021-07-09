module Intrigue
  module Task
    module BruteForceLoginHelper
      include Intrigue::Task::Web

      def bruteforce_login_and_create_issue(task_information, credentials, validator)
        _create_entity 'Uri',
                       {
                         'name' => task_information[:uri],
                         'uri' => task_information[:uri]
                       }

        work_q = build_work_queue(credentials)

        brute_force_data = execute_workers(task_information, validator, work_q)

        if brute_force_data[:success]
          _log 'Creating issue'
          _create_linked_issue task_information[:uri],
                               {
                                 proof: {
                                   "Successful login credentials": brute_force_data[:credentials],
                                   "Responses": brute_force_data[:responses]
                                 }
                               }

        end
      end

      def build_work_queue(credentials)
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

      def execute_workers(task_information, validator, work_q)
        out = {
          success: false,
          responses: [],
          credentials: []
        }

        workers = (0...task_information[:thread_count]).map do
          Thread.new do
            while credential = work_q.pop
              response = send_request_and_validate task_information, credential, validator

              next unless response

              out[:success] = true
              out[:responses] << response
              out[:credentials] << credential
            end
          rescue ThreadError
          end
        end; 'ok'
        workers.map(&:join); 'ok'

        out
      end

      def send_request_and_validate(task_information, credential, validator)
        _log "Attempting #{task_information[:uri]} with credentials #{credential}"

        response = http_request task_information[:http_method],
                                task_information[:uri],
                                credential,
                                task_information[:headers],
                                task_information[:data],
                                task_information[:follow_redirects],
                                task_information[:timeout]

        return nil unless response

        # only return response if validation was successful, else return nil.
        if validator.call(response)
          _log_good "Login successful using credentials #{credential}! Creating a page for #{task_information[:uri]}"

          response.body_utf8
        else
          return nil
          _log "Failed login on #{task_information[:uri]} using credentials: #{credential}"
        end
      end

      def get_default_login_creds_from_file
        _log 'Using default list from data/bruteforce/default_login_creds.json'
        begin
          JSON.parse(File.read("#{$intrigue_basedir}/data/bruteforce/default_login_creds.json"),
                     symbolize_names: true)
        rescue StandardError => e
          _log_error "Couldn't load #{$intrigue_basedir}/data/bruteforce/default_login_creds.json"
          []
        end
      end
    end
  end
end
