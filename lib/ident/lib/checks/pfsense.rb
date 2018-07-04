module Intrigue
module Ident
module Check
    class Pfsense < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "pfSense Firewall",
            :description => "pfSense is an open source firewall/router " +
              "computer software distribution based on FreeBSD. It is " +
              "installed on a physical computer or a virtual machine to" +
              "make a dedicated firewall/router for a network",
            :version => nil,
            :type => :content_body,
            :content => /Login to pfSense/,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
