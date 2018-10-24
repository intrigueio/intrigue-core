module Intrigue
module Ident
module Check
    class Typo3 < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Typo3",
            :product => "CMS",
            :match_details => "generator tag",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<meta name="generator" content="TYPO3 CMS"/i,
            :paths => ["#{url}"],
            :examples => ["http://www2.wessmann.com/index.php?id=52"]
          }
        ]
      end

    end
  end
  end
  end
