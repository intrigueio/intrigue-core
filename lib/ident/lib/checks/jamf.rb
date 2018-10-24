module Intrigue
module Ident
module Check
  class Jamf < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "Jamf",
          :tags => [],
          :product =>"Pro",
          :match_details =>"jamf pro login page",
          :match_type => :content_body,
          :version => nil,
          :dynamic_version => lambda { |x| _first_body_capture(x,/<title>Jamf Pro Login - Jamf Pro v(.*)</) },
          :match_content =>  /<title>Jamf Pro Login - Jamf Pro v/i,
          :examples => ["https://98.99.248.54:8443"],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
