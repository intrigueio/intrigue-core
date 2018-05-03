module Intrigue
  module Fingerprint
    class Fastly < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Fastly",
              :description => "",
              :version => "",
              :type => :content_headers,
              :content => /x-fastly-backend-reqs/
            }
          ]
        }
      end

    end
  end
end
