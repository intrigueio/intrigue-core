module Intrigue
module Ident
module Check
    class Google < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor => "Google",
            :product => "Hosted",
            :match_details => "Google Missing Page",
            :match_type => :content_body,
            :version => "",
            :match_content =>  /The requested URL <code>\/<\/code> was not found on this server\./,
            :hide => true,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Google",
            :product =>"Search Appliance",
            :match_details =>"server header reports google search appliance",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /server: Google Search Appliance/i,
            :paths => ["#{url}"],
            :examples => ["http://161.107.1.43:80"]
          }
        ]
      end

    end
  end
  end
  end
