module Intrigue
  module Fingerprint
    class Joomla < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}/administrator/manifests/files/joomla.xml",
          :checklist => [
            {
              :name => "Joomla!",
              :description => "Known Joomla Admin Page",
              :type => :content_body,
              :version => nil,
              :content => /files_joomla/,
              :references => ["https://twitter.com/GreyNoiseIO/status/987547246538391552"]
            }
          ]
        }
      end

    end
  end
end
