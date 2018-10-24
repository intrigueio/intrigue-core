module Intrigue
module Ident
module Check
    class Pardot < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Pardot",
            :product =>"Pardot",
            :match_details =>"Pardot",
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /pardot/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
