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
            :name => "Microsoft IIS 8.5",
            :description => "Microsoft IIS 8.5",
            :version => nil,
            :type => :content_body,
            :content => /<img src=\"iis-85.png\"/,
            :examples => ["http://103.1.221.151:80"],
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
