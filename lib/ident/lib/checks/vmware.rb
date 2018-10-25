module Intrigue
module Ident
module Check
    class Vmware < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "VMWare",
            :tags => ["hypervisor"],
            :product =>"ESXi",
            :match_details =>"unique page string",
            :version => nil,
            :match_type => :content_body,
            :match_content => /document.write\(\"<title>\"\ \+\ ID_EESX_Welcome/,
            :paths => ["#{url}"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwOi8vMTIuNDIuMjA1LjEyNzo4MA=="],
            :examples => ["http://12.42.205.127:80"]
          },
          {
            :type => "application",
            :vendor => "VMWare",
            :tags => ["hypervisor"],
            :product =>"Horizon View",
            :match_details =>"page title",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<title>VMware Horizon/,
            :paths => ["#{url}"]
          }
        ]
      end

    end
end
end
end
