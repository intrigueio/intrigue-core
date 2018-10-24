module Intrigue
module Ident
module Check
class Aruba < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Aruba",
        :product => "Wireless Controller",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /arubalp=/,
        :match_details =>"Matches an aruba link, generic identifier",
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
