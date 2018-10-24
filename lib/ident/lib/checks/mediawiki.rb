module Intrigue
module Ident
module Check
  class MediaWiki < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor =>"MediaWiki",
          :product =>"MediaWiki",
          :match_details =>"powered by tag",
          :match_type => :content_body,
          :version => nil,
          :match_content =>  /<a href="\/\/www.mediawiki.org\/">Powered by MediaWiki<\/a>/,
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor =>"MediaWiki",
          :product =>"MediaWiki",
          :match_details =>"generator tag",
          :match_type => :content_body,
          :match_content =>  /<meta name=\"generator\" content=\"MediaWiki/,
          :version => nil,
          :dynamic_version => lambda { |x| _first_body_capture(x,/<meta name=\"generator\" content=\"MediaWiki\ (.*?)\"\/>/) },
          :examples => ["http://2004.appsecusa.org:80"],
          :verify => ["b3dhc3AjSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHA6Ly8yMDA0LmFwcHNlY3VzYS5vcmc6ODA="],
          :paths => ["#{url}"]
        }
      ]
    end

  end
end
end
end
