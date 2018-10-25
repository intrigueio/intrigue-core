module Intrigue
module Ident
module Check
  class Lighttpd < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :tags => [],
          :vendor => "Lighttpd",
          :product =>"Lighttpd",
          :match_details =>"server header",
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /server: lighttpd/i,
          :dynamic_version => lambda { |x|
            _first_header_capture(x,/server: lighttpd\/(.*)/i,)
          },
          :examples => ["http://98.99.246.234:80"],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
