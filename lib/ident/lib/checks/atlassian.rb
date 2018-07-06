module Intrigue
module Ident
module Check
class Atlassian < Intrigue::Ident::Check::Base

  def generate_checks(uri)
    [
      {
        :name => "Atlassian BitBucket",
        :description => "Atlassian BitBucket",
        :version => nil,
        :type => :content_body,
        :content => /com.atlassian.bitbucket.server/i,
        :paths => ["#{uri}"]
      },
      {
        :name => "Atlassian Confluence",
        :description => "Atlassian Confluence",
        :version => nil,
        :type => :content_headers,
        :content => /X-Confluence-Request-Time/i,
        :paths => ["#{uri}"]
      },
      {
        :name => "Atlassian Crucible",
        :description => "Atlassian Crucible",
        :version => nil,
        :type => :content_body,
        :content => /FishEye and Crucible/,
        :dynamic_version => lambda{|x|
          if x["details"]["hidden_response_data"].scan(/Log in to FishEye and Crucible (.*)\</)[0]
            x["details"]["hidden_response_data"].scan(/Log in to FishEye and Crucible (.*)\</)[0].first
          end
        },
        :paths => ["#{uri}"]
      },
      {
        :name => "Atlassian Jira",
        :description => "Atlassian Jira",
        :version => nil,
        :type => :content_cookies,
        :content => /atlassian.xsrf.token/i,
        :dynamic_version => lambda{ |x|
          if x["details"]["hidden_response_data"].scan(/<span id="footer-build-information">(.*)-<span/)[0]
            x["details"]["hidden_response_data"].scan(/<span id="footer-build-information">(.*)-<span/)[0].first.gsub("(","")
          end
        },
        :paths => ["#{uri}"]
      }
    ]
  end
end
end
end
end
