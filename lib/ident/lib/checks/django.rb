module Intrigue
module Ident
module Check
    class Django < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Django",
            :description => "Django Admin Page",
            :version => nil,
            :type => :content_body,
            :content => /<title>Log in \| Django site admin<\/title>/,
            :paths => ["#{uri}/admin"]
          }
        ]
      end

    end
  end
  end
  end
