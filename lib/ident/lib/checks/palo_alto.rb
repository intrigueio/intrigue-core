module Intrigue
module Ident
module Check
    class PaloAlto < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :type => "application",
            :vendor => "Palo Alto Networks",
            :product =>"GlobalProtect Portal",
            :tags => ["tech:vpn"],
            :match_details =>"Pardot",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /global-protect\/login.esp/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
