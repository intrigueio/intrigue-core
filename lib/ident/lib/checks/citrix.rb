module Intrigue
module Ident
module Check
    class Citrix < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Citrix Netscaler Gateway",
            :description => "Citrix Netscaler Gateway",
            :tags => ["tech:vpn"],
            :version => nil,
            :type => :content_body,
            :content => /<title>Netscaler Gateway/,
            :hide => false,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
