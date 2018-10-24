module Intrigue
module Ident
module Check
  class Banu < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "Banu",
          :tags => [],
          :product =>"Tinyproxy",
          :match_details =>"server header",
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /server: tinyproxy/i,
          :dynamic_version => lambda { |x|
            _first_header_capture(x,/server: tinyproxy\/(.*)/i,)
          },
          :examples => ["http://208.46.69.59:8080"],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
