module Intrigue
module Ident
module Check
class AspNet < Intrigue::Ident::Check::Base

  def generate_checks(uri)
    [
      {
        :name => "ASP.NET",
        :description => "ASP.Net Error Message",
        :version => nil,
        :type => :content_body,
        :content => /^.*ASP.NET is configured.*$/i,
        :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:(.*)$/)[0].first.chomp },
        :paths => ["#{uri}"]
      },
      {
        :name => "ASP.NET",
        :description => "X-AspNet Header",
        :version => nil,
        :type => :content_headers,
        :content => /^x-aspnet-version:.*$/i,
        :dynamic_version => lambda{|x| x.body.scan(/ASP.NET Version:(.*)$/i)[0].first.chomp if x.body.scan(/ASP.NET Version:(.*)$/i)[0] },
        :paths => ["#{uri}"]
      },
      {
        :name => "ASP.NET",
        :description => "Asp.Net Default Cookie",
        :version => nil,
        :type => :content_cookies,
        :content => /ASPSESSIONID.*$/i,
        :paths => ["#{uri}"]
        #:dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnet-version/ } }
      },
      {
        :name => "ASP.NET",
        :description => "Asp.Net Default Cookie",
        :version => nil,
        :type => :content_cookies,
        :content => /ASP.NET_SessionId.*$/i,
        :paths => ["#{uri}"]
        #:dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnet-version/ } }
      },
      {
        :name => "ASP.NET MVC",
        :description => "Asp.Net MVC Header",
        :version => nil,
        :type => :content_headers,
        :content => /x-aspnetmvc-version/i,
        :paths => ["#{uri}"]
        #:dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /x-aspnetmvc-version/ } }
      },
      {
        :name => "ASP.NET",
        :description => "WebResource.axd link in the page",
        :version => nil,
        :type => :content_body,
        :content => /WebResource.axd?d=/i,
        :paths => ["#{uri}"]
        #:dynamic_version => lambda{|x| x.each_header{|k,v| return v if k =~ /WebResource.axd?d=/ } }
      }
    ]
  end
end
end
end
end
