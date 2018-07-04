module Intrigue
module Ident
module Check
class Akamai < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :name => "Akamai",
        :description => "Akamai Missing Uri",
        :version => nil,
        :type => :content_body,
        :content => /The requested URL "&#91;no&#32;URL&#93;", is invalid.<p>/,
        :hide => true,
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
