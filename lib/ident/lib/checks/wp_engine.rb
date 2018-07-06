module Intrigue
module Ident
module Check
    class WpEngine < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "WPEngine",
            :description => "WPEngine - Access site by IP",
            :version => nil,
            :type => :content_body,
            :content => /This domain is successfully pointed at WP Engine, but is not configured for an account on our platform./,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
end
end
end
