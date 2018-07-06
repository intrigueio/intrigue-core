module Intrigue
module Ident
module Check
    class Varnish < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Varnish",
            :description => "Varnish Proxy",
            :version => nil,
            :type => :content_headers,
            :content => /via: [0-9]\.[0-9] varnish/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
end
end
end
