module Intrigue
  module Fingerprint
    class Jenkins < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Jenkins",
              :description => "Jenkins",
              :version => nil,
              :type => :content_headers,
              :content => /X-Jenkins-Session/
            }
          ]
        }
      end

    end
  end
end
