module Intrigue
module Ident
module Check
    class Google < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Google",
            :description => "Google Missing Page",
            :type => :content_body,
            :version => "",
            :content => /The requested URL <code>\/<\/code> was not found on this server\./,
            :hide => true,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
