module Intrigue
module Ident
module Check
    class Magento < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Magento",
            :description => "Magento",
            :type => :content_body,
            :version => nil,
            :content => /Mage.Cookies.path/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
