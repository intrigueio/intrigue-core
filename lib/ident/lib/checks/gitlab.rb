module Intrigue
module Ident
module Check
    class Gitlab < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Gitlab",
            :description => "Gitlab",
            :version => nil,
            :type => :content_cookies,
            :content => /_gitlab_session/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
