module Intrigue
  module Fingerprint
    class Jenkins < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            { # might need to be its own, but haven't seen it yet outside jenkins
              :name => "Hudson",
              :description => "Hudson",
              :version => nil,
              :type => :content_headers,
              :content => /x-hudson/i,
              :dynamic_version => lambda { |x| x["x-hudson"] }
            },
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
              :content => /x-jenkins/i,
              :dynamic_version => lambda { |x| x["x-jenkins"] }
            }
          ]
        }
      end

    end
  end
end
