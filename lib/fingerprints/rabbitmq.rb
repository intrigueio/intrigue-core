module Intrigue
  module Fingerprint
    class Rabbitmq < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        [{
           :uri => "#{uri}",
           :checklist => [
             {
               :name => "RabbitMQ",
               :description => "RabbitMQ",
               :type => :content_body,
               :version => nil,
               :content => /RabbitMQ Management/
             }
           ]
         },
         {
          :uri => "#{uri}/api",
          :checklist => [
            {
              :name => "RabbitMQ API",
              :description => "RabbitMQ API",
              :type => :content_body,
              :version => nil,
              :content => /RabbitMQ Management HTTP API/
            }
          ]
        }]
      end
    end
  end
end
