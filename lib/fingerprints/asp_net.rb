module Intrigue
  module Fingerprint
    class AspNet < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "ASP.NET",
              :description => "ASP.Net Error Message",
              :version => nil,
              :type => :content_body,
              :content => /^.*ASP.NET is configured.*$/,
              :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:(.*)$/)[0].first.chomp }
            },
            {
              :name => "ASP.NET",
              :description => "X-AspNet Header",
              :version => nil,
              :type => :content_headers,
              :content => /^x-aspnet-version:.*$/i,
              :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:(.*)$/i)[0].first.chomp if x.body.scan(/ASP.NET Version:(.*)$/i)[0] }
            },
            {
              :name => "ASP.NET",
              :description => "Asp.Net Default Cookie",
              :version => nil,
              :type => :content_cookies,
              :content => /ASPSESSIONID.*$/,
              :dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnet-version/ } }
            },
            {
              :name => "ASP.NET",
              :description => "Asp.Net Default Cookie",
              :version => nil,
              :type => :content_cookies,
              :content => /ASP.NET_SessionId.*$/,
              :dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnet-version/ } }
            },
            {
              :name => "ASP.NET MVC",
              :description => "Asp.Net MVC Header",
              :version => nil,
              :type => :content_headers,
              :content => /x-aspnetmvc-version/,
              :dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnetmvc-version/ } }
            },
            {
              :name => "ASP.NET",
              :description => "WebResource.axd link in the page",
              :version => nil,
              :type => :content_body,
              :content => /WebResource.axd?d=/,
              :dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /WebResource.axd?d=/ } }
            }
          ]
        }
      end

    end
  end
end
