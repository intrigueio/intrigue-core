module Intrigue
  module Task
    module BruteForceLoginHelper
      include Intrigue::Task::Web

      def bruteforce_login(task_information, credentials, validator, post_data_builder = nil)
        work_q = build_work_queue(credentials)

        brute_force_data = execute_workers(task_information, validator, work_q, post_data_builder)
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

      def execute_workers(task_information, validator, work_q, post_data_builder = nil)
        out = {
          responses: [],
          credentials: []
        }

        workers = (0...task_information[:thread_count]).map do
          Thread.new do
            while credential = work_q.pop(true)

              if !post_data_builder.nil?

                next unless post_data_builder.call(task_information, credential)

              end
                send_request_and_validate task_information, credential, validator, out
                
            end
          rescue ThreadError
          end
        end

        workers.each(&:join)

        out
      end

      def send_request_and_validate(task_information, credential, validator, out)
        _log "Attempting #{task_information[:uri]} with credentials #{credential}"

        response = http_request task_information[:http_method],
                                task_information[:uri],
                                credential,
                                task_information[:headers],
                                task_information[:data],
                                task_information[:follow_redirects],
                                task_information[:timeout]

        return true unless response

        # only return response if validation was successful, else return nil.
        if validator.call(response, task_information)
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
    end
  end
end
