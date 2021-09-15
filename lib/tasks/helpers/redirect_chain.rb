module Intrigue
  module Task
    module RedirectChain
      include Intrigue::Task::Web

      def find_and_log_excessive_redirects(responses, hostname)
        all_chains = []
        max_redirect_count = Intrigue::Core::System::Config.config['redirect_issue_trigger_count'] || 10

        # iterate through responses

        _log_debug "Max redirect count: #{max_redirect_count}"
        begin
          responses.each do |r|
            next unless r || !r[:redirect_chain].empty?

            # this is to fix the ordering when saving to the DB.
            # If we change ident to return the hash props as "source" and "destination".
            # We can then remove this code.
            all_chains << r[:redirect_chain].map { |x| { 'source' => x[:from].to_s, 'destination' => x[:to].to_s } }
          end

          # drop dupes ... keep in mind this is an array of arrays
          all_chains.uniq!

          # raise an issue when the entity redirected more than the max redirect count.
          all_chains.each do |chain|
            # get the current chain's count
            redir_count = chain.count
            # check if it's above our count
            if redir_count > max_redirect_count
              _log_debug "Detected #{redirect_total_count} redirects, creating issue."
              _create_excessive_redirects_issue(hostname, redirect_complete_chain, redir_count)
            end
          end

          # TODO: ... can we fully remove this?
        rescue StandardError => e
          _log_error "Unable to fetch redirect chain: #{e}"
        end

        {
          chain: all_chains,
          count: all_chains.map { |c| c.count }.inject(0, :+)
        }
      end
    end
  end
end
