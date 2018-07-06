module Intrigue
module Ident
module Check
    class Hp < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "HP Printer",
            :description => "HP Printer",
            :version => nil,
            :type => :content_headers,
            :content => /server: HP-ChaiSOE\/1.0/i,
            :examples => ["http://69.162.52.20:80"],
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
