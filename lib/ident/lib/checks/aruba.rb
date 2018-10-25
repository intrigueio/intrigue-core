module Intrigue
module Ident
module Check
class Aruba < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "operating_system",
        :vendor => "Aruba Networks",
        :product => "Aruba OS",
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
