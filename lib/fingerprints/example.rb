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
              :type => "content",
              :content => /this is an example/
            }
          ]
        }
      end

    end
  end
end
