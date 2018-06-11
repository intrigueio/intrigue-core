module Intrigue
  module Fingerprint
    class Amazon < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Amazon ELB",
              :description => "Amazon Elastic Load Balancer",
              :url => "https://aws.amazon.com/elasticloadbalancing/",
              :version => nil,
              :type => :content_headers,
              :content => /awselb\/\d.\d/,
              :hide => true,
              :dynamic_version => lambda { |x| x["server"].match(/awselb\/(\d.\d)/).captures[0] },
              :test => "http://52.4.103.22:80"
            }
          ]
        }
      end

    end
  end
end
