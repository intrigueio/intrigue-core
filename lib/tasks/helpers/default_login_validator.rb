module Intrigue
  module Task
    module DefaultLoginValidator
    #   include Intrigue::Task::Issue
      include Intrigue::Task::Web

      def create_workers(thread_count, uri, class_creds, validator)
        work_q = Queue.new
        _log_debug 'Getting class default creds'
        class_creds.each do |creds|
          _log_debug creds
          work_q << creds
        end

        # always get default creds
        default_creds = get_default_login_creds_from_file
        _log_debug 'Getting general default creds'
        default_creds.each do |default_cred|
          _log_debug default_cred
          work_q << default_cred
        end

        build_workers(thread_count, work_q, uri, validator)
      end

      def build_workers(thread_count, work_q, uri, validator)
        workers = (0...thread_count).map do
          Thread.new do
            while cred = work_q.pop(true)
              validate_and_log_login_attempt uri.to_s, cred, validator
            end
          rescue ThreadError
          end
        end; 'ok'
        workers.map(&:join); 'ok'
      end

      def get_default_login_creds_from_file
        _log 'Using default list from data/brute_force/default_login_creds.json'
        begin
          JSON.parse(File.read("#{$intrigue_basedir}/data/brute_force/default_login_creds.json"))
        rescue StandardError => e
          _log_error "Couldn't load #{$intrigue_basedir}/data/brute_force/default_login_creds.json"
          []
        end
      end

      def validate_and_log_login_attempt(request_uri, credentials, validator = nil)
        #  _create_execessive_redirects_issue(hostname, r[:], r[:])

        _log "Attempting #{request_uri}"
        response = http_request :get, request_uri, credentials

        return false unless response
        # if response.code.to_i.between?(199, 300)
        if validator.call(response)
          _log_good "Login successful! Creating a page for #{request_uri}"
          _create_entity 'Uri',
                         'name' => request_uri,
                         'uri' => request_uri,
                         'response_code' => response.code,
                         'brute_response_body' => response.body_utf8,
                         'credentials' => credentials

        else
          _log "Failed login #{request_uri} based on code: #{response.code}"
          return false
        end
        true
      end
    end
  end
end
