module Intrigue
module Ident
module Check
    class PhpMyAdmin < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "PhpMyAdmin",
            :product => "PhpMyAdmin",
            :match_details => "PhpMyAdmin",
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /phpMyAdmin=/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
