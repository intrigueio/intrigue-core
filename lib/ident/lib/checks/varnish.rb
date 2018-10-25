module Intrigue
module Ident
module Check
    class Varnish < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Varnish-Cache",
            :product =>"Varnish",
            :match_details =>"Varnish Proxy",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /via: [0-9]\.[0-9] varnish/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
end
end
end
