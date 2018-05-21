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
              :content => /X-Jenkins-Session/i
            },
            {
              :name => "Jenkins",
              :description => "Jenkins",
              :version => nil,
              :type => :content_headers,
              :content => /x-jenkins/i
            }

          ]
        }
      end

    end
  end
end
