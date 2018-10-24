module Intrigue
module Ident
module Check
    class RuckusWireless < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Ruckus Wireless",
            :product =>"Admin",
            :match_details =>"login page for ruckus wireless device",
            :match_type => :content_body,
            :match_content =>  /<title>Ruckus Wireless Admin/i,
            :examples => [],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
