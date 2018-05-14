module Intrigue
  module Fingerprint
    class Atlassian < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Atlassian BitBucket",
              :description => "Atlassian BitBucket",
              :version => nil,
              :type => :content_body,
              :content => /com.atlassian.bitbucket.server/
            },
            {
              :name => "Atlassian Confluence",
              :description => "Atlassian Confluence",
              :version => nil,
              :type => :content_headers,
              :content => /X-Confluence-Request-Time/
            },
            {
              :name => "Atlassian Crucible",
              :description => "Atlassian Crucible",
              :version => nil,
              :type => :content_body,
              :content => /FishEye and Crucible/,
              :dynamic_version => lambda{|x|
                if x.body.scan(/Log in to FishEye and Crucible (.*)\</)[0] }
                  x.body.scan(/Log in to FishEye and Crucible (.*)\</)[0].first
                end
            },
            {
              :name => "Atlassian Jira",
              :description => "Atlassian Jira",
              :version => nil,
              :type => :content_cookies,
              :content => /atlassian.xsrf.token/,
              :dynamic_version => lambda{ |x|
                if x.body.scan(/<span id="footer-build-information">(.*)-<span/)[0]
                  x.body.scan(/<span id="footer-build-information">(.*)-<span/)[0].first.gsub("(","")  }
                end
            }
          ]
        }
      end

    end
  end
end
