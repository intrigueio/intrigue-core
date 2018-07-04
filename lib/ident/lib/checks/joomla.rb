module Intrigue
module Ident
module Check
    class Joomla < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Joomla!",
            :description => "Known Joomla Admin Page",
            :type => :content_body,
            :version => nil,
            :content => /files_joomla/i,
            :references => ["https://twitter.com/GreyNoiseIO/status/987547246538391552"],
            :paths => ["#{uri}/administrator/manifests/files/joomla.xml"]
          }
        ]
      end

    end
  end
  end
  end
