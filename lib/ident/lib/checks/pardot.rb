module Intrigue
module Ident
module Check
    class Pardot < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Pardot",
            :description => "Pardot",
            :version => nil,
            :type => :content_cookies,
            :content => /pardot/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
