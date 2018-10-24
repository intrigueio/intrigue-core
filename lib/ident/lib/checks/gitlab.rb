module Intrigue
module Ident
module Check
    class Gitlab < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Gitlab",
            :product => "Gitlab",
            :match_details => "Gitlab",
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /_gitlab_session/i,
            :dynamic_version => lambda{ |x|
                _first_body_capture(x,/window.gon={};gon.api_version=\"v([0-9\.])\"/i)
            },
            :examples => [ ],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
