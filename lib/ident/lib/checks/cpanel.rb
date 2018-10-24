module Intrigue
module Ident
module Check
    class Cpanel < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :vendor => "cPanel",
            :type => "application",
            :product =>"cPanel Hosted - Missing Page",
            :match_details =>"cPanel Hosted, but either misconfigured, or accessed via ip vs hostname?",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /URL=\/cgi-sys\/defaultwebpage.cgi/,
            :hide => true,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
