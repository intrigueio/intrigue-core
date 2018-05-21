module Intrigue
  module Fingerprint
    class Magento < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Magento",
              :description => "Magento",
              :type => :content_body,
              :version => nil,
              :content => /Mage.Cookies.path/i
            }
          ]
        }
      end

    end
  end
end
