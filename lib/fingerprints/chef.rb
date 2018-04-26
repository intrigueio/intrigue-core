module Intrigue
  module Fingerprint
    class Chef

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Chef Server",
              :description => "Chef Server",
              :version => "Unknown",
              :type => :content_body,
              :content => /<title>Chef Server<\/title>/,
              :dynamic_version => lambda{|x| x.body.scan(/Version\ (.*)\ &mdash;/)[0].first }
            }
          ]
        }
      end

    end
  end
end
