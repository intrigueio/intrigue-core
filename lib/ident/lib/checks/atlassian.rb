module Intrigue
module Ident
module Check
class Atlassian < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Atlassian",
        :product =>"BitBucket",
        :match_details =>"Atlassian BitBucket",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /com.atlassian.bitbucket.server/i,
        :paths => ["#{url}"]
      },
      {
        :type => "application",
        :vendor => "Atlassian",
        :product =>"Confluence",
        :match_details =>"Atlassian Confluence",
        :version => nil,
        :match_type => :content_headers,
        :match_content =>  /X-Confluence-Request-Time/i,
        :paths => ["#{url}"]
      },
      {
        :type => "application",
        :vendor => "Atlassian",
        :product =>"Crucible",
        :match_details =>"Atlassian Crucible",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /FishEye and Crucible/,
        :dynamic_version_field => "body",
        :dynamic_version_regex => /Log in to FishEye and Crucible (.*)\</,
        :dynamic_version => lambda{ |x|
          _first_body_capture(x, /Log in to FishEye and Crucible (.*)\</)
        },
        :paths => ["#{url}"]
      },
      {
        :type => "application",
        :vendor => "Atlassian",
        :product =>"Hipchat",
        :match_details =>"Atlassian Hipchat",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /\$\(document\).trigger\('hipchat.load'\);/,
        :examples => ["https://api.appfire.com:443"],
        :paths => ["#{url}"]
      },
      {
        :type => "application",
        :vendor => "Atlassian",
        :product =>"Jira",
        :match_details =>"Atlassian Jira",
        :version => nil,
        :match_type => :content_cookies,
        :match_content =>  /atlassian.xsrf.token=/i,
        :dynamic_version_field => "body",
        :dynamic_version_regex => /<meta name="ajs-version-number" content="(.*)">/,
        :dynamic_version => lambda{ |x|
            _first_body_capture(x,/<meta name="ajs-version-number" content="(.*)">/)
        },
        :examples => [
          "http://jira.understood.org/",
          "http://jira.londonandpartners.com:80"],
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
