module Intrigue
  module Fingerprint
    class Nagios < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Nagios",
              :description => "Nagios",
              :version => "Unknown",
              :type => :content_headers,
              :content => /nagios/
            }
          ]
        }
      end

    end
  end
end
