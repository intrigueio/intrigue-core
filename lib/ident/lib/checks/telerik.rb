module Intrigue
module Ident
module Check
    class Telerik < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Telerik Sitefinity",
            :description => "Telerik Sitefinity is an ASP.NET 2.0-based Content Management System (CMS)",
            :url => "https://www.sitefinity.com/",
            :version => nil,
            :type => :content_body,
            :content => /Telerik.Sitefinity.Resources/,
            :dynamic_version => lambda { |x|  x["details"]["hidden_response_data"].match(/Version=([\d\.]+),/).captures[0] },
            :verify_sites => [],
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
