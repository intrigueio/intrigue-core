module Intrigue
module Ident
module Check
    class Jekyll < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"Jekyll",
            :product =>"Jekyll",
            :match_details =>"server header for Jekyll",
            :references => ["https://jekyllrb.com/"],
            :match_type => :content_body,
            :match_content =>  /<meta name="generator" content="Jekyll v3.7.3"/i,
            :dynamic_version => lambda { |x|
              _first_body_capture(x,/<meta name="generator" content="Jekyll v(.*)"/i)
            },
            :examples => ["http://github.io:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
