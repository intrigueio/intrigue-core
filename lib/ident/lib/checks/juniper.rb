module Intrigue
module Ident
module Check
  class Juniper < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor =>"Juniper",
          :product =>"Junos Pulse Secure Access Service",
          :match_details => "page title",
          :match_type => :content_body,
          :references => [],
          :match_content =>  /<title>Junos Pulse Secure Access Service/,
          :version => nil,
          :examples => ["https://193.240.34.79:443"],
          :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovLzE5My4yNDAuMzQuNzk6NDQz"],
          :paths => ["#{url}"]
        }
      ]
    end

  end
end
end
end
