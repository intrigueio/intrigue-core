module Intrigue
module Ident
module Check
    class F5 < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "F5 BIG-IP APM",
            :description => "F5 BIG-IP APM",
            :tags => ["tech:vpn"],
            :version => nil,
            :type => :content_cookies,
            :content => /MRHSession/,
            :hide => false,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
