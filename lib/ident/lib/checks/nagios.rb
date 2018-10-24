module Intrigue
module Ident
module Check
    class Nagios < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Nagios",
            :product =>"Nagios",
            :match_details =>"Nagios",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /nagios/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
