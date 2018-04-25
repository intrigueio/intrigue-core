module Intrigue
  module Fingerprint
    class Gitlab

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Gitlab",
              :description => "Gitlab",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /_gitlab_session/
            }
          ]
        }
      end

    end
  end
end
