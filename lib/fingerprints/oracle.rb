module Intrigue
  module Fingerprint
    class Oracle < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Oracle Glassfish",
              :description => "Oracle / Sun GlassFish Enterprise Server",
              :url => "",
              :version => nil,
              :type => :content_headers,
              :content => /Sun GlassFish Enterprise Server/,
              :hide => true,
              :dynamic_version => lambda { |x| x["server"].match(/Sun GlassFish Enterprise Server v([\d\.])/).captures[0] },
              :verify_sites => ["http://52.4.12.185/"]
            },
            {
              :name => "Oracle Glassfish",
              :description => "Oracle / Sun GlassFish Enterprise Server",
              :url => "",
              :version => nil,
              :type => :content_headers,
              :content => /GlassFish Server Open Source Edition/,
              :hide => true,
              :dynamic_version => lambda { |x| x["server"].match(/GlassFish Server Open Source Edition\s+([\d\.]+)$/).captures[0] },
              :verify_sites => ["http://52.2.97.57:80"]
            }

          ]
        }
      end

    end
  end
end
