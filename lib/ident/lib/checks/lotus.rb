module Intrigue
module Ident
module Check
    class Lotus < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Lotus Domino",
            :description => "Lotus Domino",
            :type => :content_headers,
            :version => nil,
            :content => /server: Lotus-Domino/i,
            :examples => ["https://12.237.144.251:443"],
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
