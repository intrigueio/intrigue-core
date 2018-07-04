module Intrigue
module Ident
module Check
    class Fastly < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Fastly",
            :description => "",
            :version => "",
            :type => :content_headers,
            :content => /x-fastly-backend-reqs/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
