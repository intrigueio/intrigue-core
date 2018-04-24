module Intrigue
  module Fingerprint
    class Example

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Example App",
              :description => "Just an example",
              :version => "(Unknown Version)",
              :type => :content_body,
              :content => /this is an example/
            }
          ]
        }
      end

    end
  end
end
