module Intrigue
module Ident
module Check
class Brocade < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "hardware",
        :vendor => "Brocade",
        :product => "ICX7250-24",
        :version => nil,
        :examples => [ "http://120.127.142.126" ],
        :match_type => :content_body,
        :match_content =>  /Images\/uicx_7250_24_gfphdr_login1.gif/,
        :match_details =>"specific image",
        :paths => ["#{url}"]
      },
      {
        :type => "hardware",
        :vendor => "Brocade",
        :product => "Brocade",
        :version => nil,
        :examples => [ "http://120.127.142.126" ],
        :match_type => :content_body,
        :match_content => /<td><img src=\"Images\/brocade_logo_no_text.gif\">/,
        :match_details =>"specific image",
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
