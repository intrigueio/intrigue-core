module Intrigue
module Ident
module Check
    class Django < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Django",
            :product =>"Django",
            :version => nil,
            :match_details =>"Django Admin Page",
            :match_type => :content_body,
            :match_content =>  /<title>Log in \| Django site admin<\/title>/,
            :paths => ["#{url}/admin"]
          }
        ]
      end

    end
  end
  end
  end
