module Intrigue
  module Task
    module BruteForceLoginHelper
      #   include Intrigue::Task::Issue
      include Intrigue::Task::Web

      def bruteforce_login(task_information, credentials, validator)
        work_q = build_work_queue(credentials)
        execute_workers(task_information, validator, work_q)
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

        workers = (0...task_information[:thread_count]).map do
          Thread.new do
            while credential = work_q.pop
              validate_and_log_login_attempt task_information, credential, validator
            end
          rescue ThreadError
          end
        end; 'ok'
        workers.map(&:join); 'ok'
      end

      def validate_and_log_login_attempt(task_information, credential, validator)
        #  TODO - create issue?
        _log "Attempting #{task_information[:uri]} with credentials #{credential}"

        response = http_request task_information[:http_method],
                                task_information[:uri],
                                credential,
                                task_information[:headers],
                                task_information[:data],
                                task_information[:follow_redirects],
                                task_information[:timeout]

        return false unless response

        if validator.call(response)
          _log_good "Login successful using credentials #{credential}! Creating a page for #{task_information[:uri]}"
          _create_entity 'Uri',
                         'name' => task_information[:uri],
                         'uri' => task_information[:uri],
                         'response_code' => response.code,
                         'brute_response_body' => response.body_utf8,
                         'credentials' => credential

        else
          _log "Failed login on #{task_information[:uri]} using credentials: #{credential}"
          return false
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
          []
        end
      end
    end
  end
end
