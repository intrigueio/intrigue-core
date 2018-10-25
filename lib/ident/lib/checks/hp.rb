module Intrigue
module Ident
module Check
    class Hp < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "HP",
            :product =>"ChaiSOE",
            :version => "1.0",
            :match_type => :content_headers,
            :match_content =>  /server: HP-ChaiSOE\/1.0/i,
            :match_details =>"Generic HP Printer match",
            :examples => ["http://69.162.52.20:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
