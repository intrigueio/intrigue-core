module Intrigue
  module Task
    module DefaultLoginValidator
      #   include Intrigue::Task::Issue
      include Intrigue::Task::Web

      def get_workers(thread_count, uri, class_creds, validator)
        work_q = build_work_queue(class_creds)
        build_workers(thread_count, work_q, uri, validator)
      end

      def build_work_queue(class_creds)

        helper_hash_array = []
        _log_debug 'Adding task default credentials to worker queue'
        class_creds.each do |creds|
          _log_debug creds
          helper_hash_array << creds
        end

        # always get default creds
        default_creds = get_default_login_creds_from_file

        _log_debug 'Adding general default credentials to worker queue'
        default_creds.each do |default_cred|
          _log_debug default_cred
          helper_hash_array << normalize_hash(default_cred)
        end
        # release memory
        default_creds.clear

        work_q = Queue.new
        # TODO - too many iterations.
        helper_hash_array.uniq.each do |unique_values|
          work_q << unique_values
        end

        # release memory
        helper_hash_array.clear

        work_q
      end

      def normalize_hash(login_hash)
        {
          user: login_hash['user'],
          password: login_hash['password']
        }
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

      def validate_and_log_login_attempt(request_uri, credentials, validator)
        #  TODO - create issue?

        _log "Attempting #{request_uri}"
        response = http_request :get, request_uri, credentials

        return false unless response

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
