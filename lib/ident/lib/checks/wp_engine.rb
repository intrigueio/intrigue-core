module Intrigue
module Ident
module Check
    class WpEngine < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"WPEngine",
            :tags => ["hosting_provider"],
            :product =>"WPEngine",
            :match_details =>"WPEngine - Access site by IP",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /This domain is successfully pointed at WP Engine, but is not configured for an account on our platform./,
            :hide => true,
            :paths => ["#{url}"]
          }
        ]
      end

    end
end
end
end
