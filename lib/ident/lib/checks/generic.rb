module Intrigue
module Ident
module Check
    class Generic < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "none",
            :vendor => nil,
            :product =>"Authentication Required",
            :match_details =>"www-authenticate header",
            :tags => [],
            :version => nil,
            :hide => true,
            :match_type => :content_headers,
            :match_content =>  /^www-authenticate:.*$/,
            :paths => ["#{url}"],
            :examples => ["https://160.69.1.115:443"]
          },
          {
            :type => "none",
            :vendor => nil,
            :product => "Generic Unauthorized",
            :match_details =>"Generic Unauthorized",
            :tags => ["error_page"],
            :version => nil,
            :hide => true,
            :match_type => :content_body,
            :match_content =>  /<STRONG>401 Unauthorized/,
            :paths => ["#{url}"]
          },
          {
            :type => "none",
            :vendor => nil,
            :product => "Content Missing (404)",
            :match_details =>"Content Missing (404) - Could be an API, or just serving something at another location. TODO ... is this ECS-specific? (check header)",
            :tags => ["error_page"],
            :version => nil,
            :hide => true,
            :match_type => :content_body,
            :match_content =>  /<title>404 - Not Found<\/title>/,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
