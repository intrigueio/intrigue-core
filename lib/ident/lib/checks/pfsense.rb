module Intrigue
module Ident
module Check
    class Pfsense < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "pfSense",
            :product =>"pfSense",
            :match_details => "unique body content",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /Login to pfSense/,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
