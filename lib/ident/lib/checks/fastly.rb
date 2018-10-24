module Intrigue
module Ident
module Check
    class Fastly < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor =>"Fastly",
            :product =>"Fastly",
            :match_details =>"header",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /x-fastly-backend-reqs/i,
            :paths => ["#{url}"]
          },
          {
            :type => "service",
            :vendor =>"Fastly",
            :product =>"Fastly",
            :match_details =>"error content in page",
            :version => nil,
            :hide => true,
            :match_type => :content_body,
            :match_content =>  /<title>Fastly error: unknown domain/i,
            :examples => ["http://151.101.1.224:80"],
            :verify => ["ZXRzeSNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cDovLzE1MS4xMDEuMS4yMjQ6ODA="],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
