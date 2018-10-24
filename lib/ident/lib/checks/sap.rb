module Intrigue
module Ident
module Check
    class Sap < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"SAP",
            :product =>"NetWeaver",
            :match_details =>"cookie",
            :references => [
              "https://apps.support.sap.com/sap/support/knowledge/preview/en/2082323",
              "https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/scanner/sap/sap_soap_rfc_pfl_check_os_file_existence.rb"
            ],
            :match_type => :content_cookies,
            :match_content =>  /sap-usercontext=sap-language=/i,
            :examples => ["http://204.29.196.102:80"],
            :verify => ["dW5kZXJhcm1vdXIjSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHA6Ly8yMDQuMjkuMTk2LjEwMjo4MA=="],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor =>"SAP",
            :product =>"NetWeaver",
            :match_details =>"location header",
            :references => [
              "https://blogs.sap.com/2016/05/19/hp-loadrunner-scripts-for-webui/"
            ],
            :match_type => :content_headers,
            :match_content =>  /bD1lbiZjPTEwMCZkPW1pbg==/i,
            :examples => ["http://onlinepaymentstest.underarmour.com:80"],
            :verify => ["dW5kZXJhcm1vdXIjSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHA6Ly9vbmxpbmVwYXltZW50c3Rlc3QudW5kZXJhcm1vdXIuY29tOjgw"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
