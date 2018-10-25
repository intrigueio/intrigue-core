module Intrigue
module Ident
module Check
    class F5 < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "F5",
            :product =>"BIG-IP Access Policy Manager",
            :match_details =>"F5 BIG-IP Access Policy Manager default cookie",
            :tags => ["load_balancer"],
            :version => nil,
            :match_type => :content_cookies,
            :match_content => /MRHSession/,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "F5",
            :product =>"BIG-IP Access Policy Manager",
            :match_details =>"F5 BIG-IP APM default logo",
            :tags => ["load_balancer"],
            :version => nil,
            :references => ["https://support.f5.com/kb/en-us/products/big-ip_apm/manuals/product/apm-customization-11-6-0/3.html"],
            :match_type => :content_body,
            :match_content => /<img src="\/public\/images\/my\/tr.gif\//,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "hardware",
            :vendor => "F5",
            :product =>"BIG-IP Local Traffic Manager",
            :match_details =>"F5 BIG-IP Load balancer cookie",
            :tags => ["tech:load_balancer"],
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /BIGipServer/,
            :examples => ["https://reset.oxy.com:443"],
            :hide => false,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
