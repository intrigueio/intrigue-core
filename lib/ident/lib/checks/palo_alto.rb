module Intrigue
module Ident
module Check
    class PaloAlto < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Palo Alto Networks GlobalProtect Portal",
            :tags => ["tech:vpn"],
            :description => "Pardot",
            :version => nil,
            :type => :content_body,
            :content => /global-protect\/login.esp/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
