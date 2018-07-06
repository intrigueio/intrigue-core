module Intrigue
module Ident
module Check
    class Vmware < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "VMWare Horizon",
            :description => "VMWare Horizon",
            :version => nil,
            :type => :content_body,
            :content => /<title>VMware Horizon/,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
end
end
end
