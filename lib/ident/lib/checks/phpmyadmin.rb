module Intrigue
module Ident
module Check
    class PhpMyAdmin < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "PhpMyAdmin",
            :description => "PhpMyAdmin",
            :version => nil,
            :type => :content_cookies,
            :content => /phpMyAdmin=/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
