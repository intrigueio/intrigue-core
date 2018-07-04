module Intrigue
module Ident
module Check
    class Cpanel < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "cPanel Hosted - Missing Page",
            :description => "cPanel Hosted, but either misconfigured, or accessed via ip vs hostname?",
            :version => "",
            :type => :content_body,
            :content => /URL=\/cgi-sys\/defaultwebpage.cgi/,
            :hide => true,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
