module Intrigue
  module Task
    class SonicWallDefaultLogin < BaseTask
      include Intrigue::Task::Web
      include Intrigue::Task::DefaultLoginValidator

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
            { user: 'admin', password: 'password' }
          ]
        }
      end

      def run
        super
        fingerprint = _get_entity_detail('fingerprint')

        return false unless vendor?(fingerprint, 'SonicWall') && tag?(fingerprint, 'Login Panel')

        # Get options
        uri = _get_entity_name
        thread_count = _get_option('threads')

        response = http_request :get, uri.to_s

        # check for sanity
        unless response
          _log_error 'Unable to connect!'
          return false
        end

        # Create our queue of work from the known creds for the product
        get_workers(thread_count, uri, self.class.metadata[:credentials], method(:validator))
      end

      # custom validator, each default login task will have its own.
      # some tasks might require a more complex approach.
      def validator(response)
        !response.body_utf8.match(/id="authFrm"/i) && !response.body_utf8.match(%r{Incorrect name/password}i) && response.code.to_i.between?(
          199, 300
        )
      end
    end
  end
end
