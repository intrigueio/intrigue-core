module Intrigue
module Ident
module Check
    class Lotus < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Lotus",
            :product =>"Domino",
            :match_details =>"Lotus Domino",
            :match_type => :content_headers,
            :version => nil,
            :match_content =>  /server: Lotus-Domino/i,
            :examples => [
              "https://12.237.144.251:443"
            ],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
