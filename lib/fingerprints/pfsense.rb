module Intrigue
  module Fingerprint
    class Pfsense

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "pfSense Firewall",
              :description => "pfSense is an open source firewall/router " +
                "computer software distribution based on FreeBSD. It is " +
                "installed on a physical computer or a virtual machine to" +
                "make a dedicated firewall/router for a network",
              :version => "Unknown",
              :type => :content_body,
              :content => /Login to pfSense/
            }
          ]
        }
      end

    end
  end
end
