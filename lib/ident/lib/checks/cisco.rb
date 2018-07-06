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
          },
          {
            :name => "Cisco SSL VPN",
            :description => "Cisco SSL VPN",
            :tags => ["tech:vpn"],
            :version => nil,
            :type => :content_body,
            :content => /document.location.replace\(\"\/\+CSCOE\+\/logon.html\"\);/,
            :examples => ["https://12.237.144.250:443"],
            :hide => false,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cisco Router",
            :description => "Cisco Router",
            :version => nil,
            :type => :content_headers,
            :content => /server: cisco-IOS/,
            :hide => false,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
