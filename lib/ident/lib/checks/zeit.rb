module Intrigue
module Ident
module Check
    class Zeit < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Zeit",
            :product =>"Next.js",
            :match_details =>"x-powered-by header",
            :references => ["https://zeit.co/blog/next"],
            :match_type => :content_headers,
            :match_content =>  /x-powered-by: Next.js/i,
            :dynamic_version => lambda { |x|
              _first_header_capture(x,/sx-powered-by: Next.js\ (.*)/i)
            },
            :examples => ["http://static.invisionapp.com:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
