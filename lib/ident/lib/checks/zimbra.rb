module Intrigue
module Ident
module Check
    class Zimbra < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"Zimbra",
            :product =>"Server",
            :match_details =>"login page for zimbra",
            :match_type => :content_body,
            :match_content =>  /<title>Zimbra Web Client Sign In/i,
            :examples => ["https://219.84.198.177:443"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
