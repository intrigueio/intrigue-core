module Intrigue
  module Fingerprint
    class Pardot < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Pardot",
              :description => "Pardot",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /pardot/
            }
          ]
        }
      end

    end
  end
end
