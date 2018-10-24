module Intrigue
module Ident
module Check
    class Magento < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Magento",
            :product =>"Magento",
            :match_details =>"Magento",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /Mage.Cookies.path/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
