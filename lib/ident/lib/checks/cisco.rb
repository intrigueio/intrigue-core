module Intrigue
module Ident
module Check
    class Cisco < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Cisco",
            :product => "Adaptive Security Device Manager",
            :match_details => "page title",
            :version => nil,
            :dynamic_version => lambda {|x| _first_body_capture(x,/<title>Cisco ASDM (.*?)<\/title>/)},
            :match_type => :content_body,
            :match_content =>  /<title>Cisco ASDM/,
            :hide => false,
            :examples => ["https://194.107.112.4:443"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovLzE5NC4xMDcuMTEyLjQ6NDQz"],
            :paths => ["#{url}"]
          },
          {
            :type => "hardware",
            :vendor => "Cisco",
            :product => "Email Security Appliance",
            :match_details => "page title",
            :version => nil,
            :dynamic_version => lambda {|x| _first_body_capture(x,/Email Security Appliance   (.*?) \(/)},
            :match_type => :content_body,
            :match_content =>  /<title>        Cisco         Email Security Appliance/,
            :hide => false,
            :examples => ["https://200.142.198.180:443"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovLzIwMC4xNDIuMTk4LjE4MDo0NDM="],
            :paths => ["#{url}"]
          },
          {
            :type => "hardware",
            :vendor => "Cisco",
            :product => "Meraki",
            :match_details => "Meraki logo on an on-prem box",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<img id="header_logo" src="images\/meraki-logo.png"/,
            :hide => false,
            :examples => [],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Cisco",
            :product =>"SSL VPN",
            :match_details =>"Cisco SSL VPN",
            :tags => ["tech:vpn"],
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /webvpn/,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Cisco",
            :product =>"SSL VPN",
            :match_details =>"Cisco SSL VPN",
            :tags => ["tech:vpn"],
            :version => nil,
            :match_type => :content_body,
            :match_content => /document.location.replace\(\"\/\+CSCOE\+\/logon.html\"\)/,
            :examples => [
              "https://12.237.144.250:443",
              "http://12.150.243.178:80"],
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Cisco",
            :product => "Router",
            :match_details => "Cisco Router",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /server: cisco-IOS/,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Cisco",
            :product =>"vManage",
            :match_details => "page title",
            :tags => [],
            :version => nil,
            :match_type => :content_body,
            :match_content => /<title>Cisco vManage/,
            :examples => ["http://129.41.171.244:80"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwOi8vMTI5LjQxLjE3MS4yNDQ6ODA="],
            :hide => false,
            :paths => ["#{url}"]
          },
        ]
      end

    end
  end
  end
  end
