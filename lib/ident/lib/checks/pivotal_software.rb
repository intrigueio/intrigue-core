module Intrigue
module Ident
module Check
    class PivotalSoftware < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"Pivotal Software",
            :product =>"Spring Framework",
            :match_details =>"Standard Spring MVC error page",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :paths => ["#{url}/error.json"]
          },
          {
            :type => "application",
            :vendor => "Pivotal Software",
            :product => "RabbitMQ",
            :match_details =>"RabbitMQ",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /RabbitMQ Management/,
            :paths => ["#{url}"]
          },
          {
           :type => "application",
           :vendor => "Pivotal Software",
           :product => "RabbitMQ",
           :match_details => "RabbitMQ API",
           :match_type => :content_body,
           :version => nil,
           :match_content =>  /RabbitMQ Management HTTP API/,
           :paths => ["#{url}/api"]
         }
        ]
      end

    end
  end
  end
  end
