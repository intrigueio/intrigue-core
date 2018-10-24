module Intrigue
module Ident
module Check
    class Citrix < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "Netscaler Gateway",
            :match_details => "Citrix Netscaler Gateway",
            :tags => ["tech:vpn"],
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<title>Netscaler Gateway/,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "Netscaler Gateway",
            :match_details => "(often) customized logon page - netscaler gateway",
            :tags => ["tech:vpn"],
            :version => nil,
            :match_type => :content_body,
            :match_content => /CTXMSAM_LogonFont/,
            :hide => false,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "Netscaler Gateway",
            :match_details => "misspelled content-length header",
            :tags => ["tech:vpn"],
            :references => ["https://support.citrix.com/article/CTX211605"],
            :version => nil,
            :match_type => :content_headers,
            :match_content => /^cteonnt-length:.*$/,
            :hide => false,
            :paths => ["#{url}"],
            :examples => ["http://204.29.196.116:80"]
          },
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "Netscaler Gateway",
            :match_details => "cookie",
            :tags => ["tech:vpn"],
            :references => ["https://support.citrix.com/article/CTX131488"],
            :version => nil,
            :match_type => :content_cookies,
            :match_content => /citrix_ns_id=/,
            :hide => false,
            :paths => ["#{url}"],
            :verify => ["dW5kZXJhcm1vdXIjSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHA6Ly8yMDQuMjkuMTk2LjEwMjo4MA=="],
            :examples => ["http://204.29.196.102:80"]
          },
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "XenServer",
            :match_details => "page title",
            :tags => ["tech:hypervisor"],
            :references => [""],
            :version => nil,
            :dynamic_version => lambda { |x| _first_body_capture(x,/<title>XenServer (.*?)<\/title>/) },
            :match_type => :content_body,
            :match_content => /<title>XenServer/,
            :hide => false,
            :paths => ["#{url}"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwOi8vMTU4Ljg1LjE3My4zNzo4MA=="],
            :examples => ["http://158.85.173.37:80"]
          },
          {
            :type => "application",
            :vendor => "Citrix",
            :product => "XenServer",
            :match_details => "page title",
            :tags => ["tech:hypervisor"],
            :references => [""],
            :version => nil,
            :dynamic_version => lambda { |x| _first_body_capture(x,/<title>Welcome to Citrix XenServer (.*?)<\/title>/) },
            :match_type => :content_body,
            :match_content => /<title>Welcome to Citrix XenServer/,
            :hide => false,
            :paths => ["#{url}"],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovLzIzLmRjLjU1OWUuaXA0LnN0YXRpYy5zbC1yZXZlcnNlLmNvbTo0NDM="],
            :examples => ["https://23.dc.559e.ip4.static.sl-reverse.com:443"]
          }
        ]
      end

    end
  end
  end
  end
