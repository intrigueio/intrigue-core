module Intrigue
  module Fingerprint
    class Jenkins

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Jenkins",
              :description => "Jenkins",
              :version => "Unknown",
              :type => :content_headers,
              :content => /X-Jenkins-Session/
            }
          ]
        }
      end

    end
  end
end
