module Intrigue
  module Task
    class SonicWallDefaultLogin < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'vuln/brute_force/sonicwall_login_vuln',
          pretty_name: 'Vuln Check - Sonicwall Default Login Credentials',
          authors: [''],
          description: 'Bruteforce Sonicwall Default Login Credentials',
          type: 'Vuln',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [
            { 'type' => 'Uri', 'details' => { 'name' => 'http://intrigue.io' } }
          ],
          allowed_options: [
            { name: 'threads', regex: 'integer', default: 10 }
          ],
          created_types: ['Uri'],
          credentials: [
            { user: 'admin', password: 'password' },
            { user: 'root', password: 'password' }
          ]
        }
      end

      def run
        super
        # TODO - split the responsibilities of this class
        fingerprint = _get_entity_detail('fingerprint')

        return false unless is_product?(fingerprint,
                                        'Network Security Appliance') && has_tag?(fingerprint, 'Login Panel')

        # Get options
        uri = _get_entity_name
        opt_threads = _get_option('threads')

        response = http_request :get, uri.to_s

        # check for sanity
        unless response
          _log_error 'Unable to connect!'
          return false
        end

        # Create our queue of work from the known creds for the product
        work_q = Queue.new

        self.class.metadata[:credentials].each do |creds|
          _log_debug creds
          work_q << creds
        end
        # always get default creds

        default_creds = get_default_login_creds_from_file

        default_creds.each do |default_creds|
          _log_debug default_creds
          work_q << default_creds
        end

        workers = build_workers(opt_threads, work_q, uri)
      end

      def build_workers(thread_count, work_q, uri)
        workers = (0...thread_count).map do
          Thread.new do
            while cred = work_q.pop(true)
              attempt_login uri.to_s, cred
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

      def attempt_login(request_uri, credentials)
        _log "Attempting #{request_uri}"
        response = http_request :get, request_uri, credentials

        return false unless response

        # TODO - this is wrong, need to figure out what a successful login looks like.
        if response.code.to_i.between?(199, 300)
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
