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
            :dynamic_version => lambda{ |x|
              m = nil
              x.each_header{|h,v| m = v if (h == "via" && v =~ /varnish/) }
              m.gsub("varnish ","") if m
            },
            :paths => ["#{uri}"]
          }
        ]
      end

    end
end
end
end
