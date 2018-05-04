module Intrigue
  module Fingerprint
    class Generic < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Content Missing (404)",
              :description => "Content Missing (404) - Could be an API, or just serving something at another location. TODO ... is this ECS-specific? (check header)",
              :version => nil,
              :type => :content_body,
              :content => /<title>404 - Not Found<\/title>/
            }
          ]
        }
      end

    end
  end
end
