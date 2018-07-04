module Intrigue
module Ident
module Check
    class Rabbitmq < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
           {
             :name => "RabbitMQ",
             :description => "RabbitMQ",
             :type => :content_body,
             :version => nil,
             :content => /RabbitMQ Management/,
             :paths => ["#{uri}"]
           },
           {
            :name => "RabbitMQ API",
            :description => "RabbitMQ API",
            :type => :content_body,
            :version => nil,
            :content => /RabbitMQ Management HTTP API/,
            :paths => ["#{uri}/api"]
          }
        ]
      end
    end
  end
  end
  end
