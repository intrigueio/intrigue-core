module Intrigue
  module Fingerprint
    class Akamai < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Akamai",
              :description => "Akamai Missing Uri",
              :version => nil,
              :type => :content_body,
              :content => /The requested URL "&#91;no&#32;URL&#93;", is invalid.<p>/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
