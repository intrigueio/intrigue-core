module Intrigue
module Ident
module Check
    class Yaws < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Yaws",
            :product =>"Yaws",
            :match_details =>"server header",
            :references => ["https://en.wikipedia.org/wiki/Yaws_(web_server)"],
            :match_type => :content_headers,
            :match_content =>  /server: Yaws/i,
            :dynamic_version => lambda { |x|
              _first_header_capture(x,/server: Yaws (.*)/i)
            },
            :examples => ["https://158.85.224.176:443"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovLzE1OC44NS4yMjQuMTc2OjQ0Mw=="],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
