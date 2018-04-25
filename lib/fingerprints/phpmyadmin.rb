module Intrigue
  module Fingerprint
    class PhpMyAdmin

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "PhpMyAdmin",
              :description => "PhpMyAdmin",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /phpMyAdmin=/
            }
          ]
        }
      end

    end
  end
end
