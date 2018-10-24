module Intrigue
module Ident
module Check
    class Heroku < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor => "Heroku",
            :product =>"Heroku",
            :match_details =>"Heroku",
            :tags => ["hosting_provider"],
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /herokucdn.com\/error-pages\/no-such-app.html/,
            :hide => true,
            :examples => ["http://54.209.64.71:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
