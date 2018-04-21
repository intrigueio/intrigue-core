module Intrigue
  module Fingerprint
    class Joomla

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}/administrator/manifests/files/joomla.xml",
          :checklist => [
            {
              :name => "Joomla!",
              :description => "Known Joomla Admin Page",
              :type => "content",
              :version => "(Unknown Version)",
              :content => /files_joomla/,
              :test_site => "http://studio-caractere.fr",
              :references => ["https://twitter.com/GreyNoiseIO/status/987547246538391552"]
            }
          ]
        }
      end

    end
  end
end
