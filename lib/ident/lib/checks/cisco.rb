module Intrigue
module Ident
module Check
    class Cisco < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Cisco SSL VPN",
            :description => "Cisco SSL VPN",
            :tags => ["tech:vpn"],
            :version => nil,
            :type => :content_cookies,
            :content => /webvpn/,
            :hide => false,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
