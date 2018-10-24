module Intrigue
module Ident
module Check
    class Craft < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :vendor => "Craft",
            :type => "application",
            :product =>"CMS",
            :match_details =>"csrf protection cookie",
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /CRAFT_CSRF_TOKEN/,
            :hide => true,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
