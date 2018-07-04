module Intrigue
module Ident
module Check
    class Nagios < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Nagios",
            :description => "Nagios",
            :version => nil,
            :type => :content_headers,
            :content => /nagios/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
