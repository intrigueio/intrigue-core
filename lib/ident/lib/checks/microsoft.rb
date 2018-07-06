module Intrigue
module Ident
module Check
    class Microsoft < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Microsoft Forefront TMG",
            :description => "Microsoft Forefront Threat Management Gateway",
            :version => nil,
            :type => :content_cookies,
            :content => /<title>Microsoft Forefront TMG/,
            :paths => ["#{uri}"]
          },
          {
            :name => "Microsoft IIS 8.0",
            :description => "Microsoft IIS 8.0",
            :version => nil,
            :type => :content_body,
            :content => /<img src=\"iis-8.png\"/,
            :examples => ["http://66.162.2.18:80"],
            :paths => ["#{uri}"]
          },
          {
            :name => "Microsoft IIS 8.5",
            :description => "Microsoft IIS 8.5",
            :version => nil,
            :type => :content_body,
            :content => /<img src=\"iis-85.png\"/,
            :examples => ["http://103.1.221.151:80"],
            :paths => ["#{uri}"]
          },
          {
            :name => "Microsoft Outlook Web Access",
            :description => "Microsoft Outlook Web Access",
            :version => nil,
            :type => :content_headers,
            :content => /x-owa-version/,
            :dynamic_version => lambda { |x| x["x-owa-version"] },
            :paths => ["#{uri}"]
          },
          {
            :name => "Microsoft Generic Error - 403",
            :description => "Microsoft Generic Error - 403",
            :tags => ["error_page"],
            :version => nil,
            :type => :content_body,
            :hide => true,
            :content => /403 Forbidden. The server denied the specified Uniform Resource Locator (URL)/,
            :paths => ["#{uri}"]
          },
          {
            :name => "Microsoft Generic Error - 503",
            :description => "Microsoft Generic Error - 503",
            :tags => ["error_page"],
            :version => nil,
            :type => :content_body,
            :hide => true,
            :content => /HTTP Error 503. The service is unavailable./,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
