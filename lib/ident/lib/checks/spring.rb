module Intrigue
module Ident
module Check
    class Spring < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Spring",
            :description => "Standard Spring MVC error page",
            :type => :content_body,
            :version => nil,
            :content => /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :paths => ["#{uri}/error.json"]
          }
        ]
      end

    end
  end
  end
  end
