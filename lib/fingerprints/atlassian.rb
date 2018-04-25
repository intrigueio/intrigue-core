module Intrigue
  module Fingerprint
    class Atlassian

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Atlassian BitBucket",
              :description => "Atlassian BitBucket",
              :version => "Unknown",
              :type => :content_body,
              :content => /com.atlassian.bitbucket.server/
            },
            {
              :name => "Atlassian Confluence",
              :description => "Confluence",
              :version => "Unknown",
              :type => :content_headers,
              :content => /X-Confluence-Request-Time/
            },
            {
              :name => "Atlassian Jira",
              :description => "Jira",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /atlassian.xsrf.token/,
              :dynamic_version => lambda{|x| x.body.scan(/<span id="footer-build-information">(.*)-<span/)[0].first.gsub("(","") }
            }
          ]
        }
      end

    end
  end
end
