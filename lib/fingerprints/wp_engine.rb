module Intrigue
  module Fingerprint
    class WpEngine < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "WPEngine",
              :description => "WPEngine - Access site by IP",
              :version => "",
              :type => :content_body,
              :content => /This domain is successfully pointed at WP Engine, but is not configured for an account on our platform./
            }
          ]
        }
      end

    end
  end
end
