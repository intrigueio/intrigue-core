module Intrigue
module Ident
module Check
    class OpenResty < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"OpenResty",
            :product =>"OpenResty",
            :match_details =>"server header for OpenResty",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /server: openresty/i,
            :examples => ["http://54.164.224.102:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
