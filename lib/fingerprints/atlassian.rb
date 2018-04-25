module Intrigue
  module Fingerprint
    class Atlassian

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Jira",
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
