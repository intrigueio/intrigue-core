module Intrigue
module Ident
module Check
    class Rabbitmq < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
           {
             :type => "application",
             :vendor => "RabbitMQ",
             :product => "RabbitMQ",
             :match_details =>"RabbitMQ",
             :match_type => :content_body,
             :version => nil,
             :match_content =>  /RabbitMQ Management/,
             :paths => ["#{url}"]
           },
           {
            :type => "application",
            :vendor => "RabbitMQ",
            :product => "RabbitMQ API",
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
