module Intrigue
module Ident
module Check
    class MediaWiki < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "MediaWiki",
            :description => "MediaWiki",
            :type => :content_body,
            :version => nil,
            :content => /<a href="\/\/www.mediawiki.org\/">Powered by MediaWiki<\/a>/,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end


=begin
all_checks = [{
  :uri => "#{uri}",
  :checklist => [
  {
    :name => "Yoast Wordpress SEO Plugin", # won't be used if we have
    :description => "Yoast Wordpress SEO Plugin",
    :type => "content",
    :content => /<!-- \/ Yoast WordPress SEO plugin. -->/,
    :test_site => "https://ip-50-62-231-56.ip.secureserver.net",
    :dynamic_name => lambda{|x| x.scan(/the Yoast WordPress SEO plugin v.* - h/)[0].gsub("the ","").gsub(" - h","") }
  }
]},
=end
