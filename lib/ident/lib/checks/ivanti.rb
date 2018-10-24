module Intrigue
module Ident
module Check
  class Ivanti < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "Ivanti",
          :tags => [],
          :product =>"LANDESK Appliance",
          :match_details =>"matched title",
          :match_type => :content_body,
          :version => nil,
          :references => ["https://community.ivanti.com/community/all-products/systems/cloudservices"],
          :match_content =>  /<title>LANDESK\(R\) Cloud Services Appliance/i,
          :examples => ["https://techcentral.hormel.com/"],
          :verify => ["aG9ybWVsZm9vZHMjSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHBzOi8vdGVjaGNlbnRyYWwuaG9ybWVsLmNvbTo0NDM="],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
