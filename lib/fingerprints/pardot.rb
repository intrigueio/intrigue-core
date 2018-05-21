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
              :version => nil,
              :type => :content_cookies,
              :content => /pardot/i
            }
          ]
        }
      end

    end
  end
end
