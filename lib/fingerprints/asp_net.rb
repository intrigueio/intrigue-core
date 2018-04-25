module Intrigue
  module Fingerprint
    class AspNet

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "ASP.NET",
              :description => "ASP.Net Error Message",
              :version => "Unknown",
              :type => :content_body,
              :content => /^.*ASP.NET is configured.*$/,
              :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:.*$/)[0].gsub("ASP.NET Version:","").chomp }
            },
            {
              :name => "ASP.NET",
              :description => "X-AspNet Header",
              :version => "Unknown",
              :type => :content_headers,
              :content => /^X-AspNet-Version:.*$/,
              :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:.*$/)[0].gsub("ASP.NET Version:","").chomp }
            },
            {
              :name => "ASP.NET",
              :description => "Asp.Net Default Cookie",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /^.*ASPSESSIONID.*$/
            },
            {
              :name => "ASP.NET",
              :description => "Asp.Net Default Cookie",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /^.*ASP.NET_SessionId.*$/
            }
          ]
        }
      end

    end
  end
end
