module Intrigue
module Ident
module Check
    class Oracle < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Oracle Glassfish",
            :description => "Oracle / Sun GlassFish Enterprise Server",
            :url => "",
            :version => nil,
            :type => :content_headers,
            :content => /Sun GlassFish Enterprise Server/,
            :hide => true,
            :dynamic_version => lambda { |x| x["details"]["headers"].join("\n").match(/Sun GlassFish Enterprise Server v([\d\.])/).captures[0] },
            :examples => ["http://52.4.12.185/"],
            :paths => ["#{uri}"]
          },
          {
            :name => "Oracle Glassfish",
            :description => "Oracle / Sun GlassFish Enterprise Server",
            :url => "",
            :version => nil,
            :type => :content_headers,
            :content => /GlassFish Server Open Source Edition/,
            :hide => true,
            :dynamic_version => lambda { |x| x["details"]["headers"].join("\n").match(/GlassFish Server Open Source Edition\s+([\d\.]+)$/).captures[0] },
            :examples => ["http://52.2.97.57:80"],
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
