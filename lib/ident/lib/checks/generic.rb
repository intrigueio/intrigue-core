module Intrigue
module Ident
module Check
    class Generic < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Content Missing (404)",
            :description => "Content Missing (404) - Could be an API, or just serving something at another location. TODO ... is this ECS-specific? (check header)",
            :version => nil,
            :type => :content_body,
            :content => /<title>404 - Not Found<\/title>/,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
