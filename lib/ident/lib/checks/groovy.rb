module Intrigue
module Ident
module Check
    class Groovy < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Groovy",
            :product =>"Groovy",
            :match_details =>"Groovy error page",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /Error processing GroovyPageView:/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
