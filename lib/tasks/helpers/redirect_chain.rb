module Intrigue
  module Task
    module RedirectChain
      include Intrigue::Task::Web

      def find_and_log_excessive_redirects(responses, hostname)
        redirect_complete_chain = []
        redirect_total_count = 0

        # iterate through responses
        begin
          max_redirect_count = Intrigue::Core::System::Config.config['redirect_issue_trigger_count']

          max_redirect_count = 10 if max_redirect_count.nil? || max_redirect_count.to_s.empty?

          _log_debug "Max redirect count: #{max_redirect_count}"

          responses.each do |r|
            next unless r || !r[:redirect_chain].empty?

            # this is to fix the ordering when saving to the DB.
            # If we change ident to return the hash props as "source" and "destination".
            # We can then remove this code.
            r[:redirect_chain].each do |x|
              redirect_complete_chain << {
                'source' => x[:from].to_s,
                'destination' => x[:to].to_s
              }
            end
            redirect_complete_chain = redirect_complete_chain.uniq
          end

          redirect_total_count = redirect_complete_chain.count

          # raise an issue when the entity redirected more than the max redirect count.
          if redirect_total_count > max_redirect_count
            _log_debug "Detected #{redirect_total_count} redirects, creating issue."
            _create_execessive_redirects_issue(hostname, redirect_complete_chain, redirect_total_count)
          end
        rescue StandardError => e
          _log_error "Unable to fetch redirect chain: #{e}"
        end

        {
          chain: redirect_complete_chain,
          count: redirect_total_count
        }
      end
    end
  end
end
