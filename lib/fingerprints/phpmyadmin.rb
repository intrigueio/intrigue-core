module Intrigue
  module Fingerprint
    class PhpMyAdmin < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "PhpMyAdmin",
              :description => "PhpMyAdmin",
              :version => nil,
              :type => :content_cookies,
              :content => /phpMyAdmin=/
            }
          ]
        }
      end

    end
  end
end
