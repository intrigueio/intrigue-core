module Intrigue
  module Fingerprint
    class Magento

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Magento",
              :description => "Magento",
              :type => :content_body,
              :version => "(Unknown Version)",
              :content => /Mage.Cookies.path/,
              :test_site => "https://admin.chwine.com"
            }
          ]
        }
      end

    end
  end
end
