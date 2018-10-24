module Intrigue
module Ident
module Check
class Docuwiki < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Docuwiki",
        :product => "Docuwiki",
        :version => nil,
        :match_type => :content_headers,
        :match_content =>  /DokuWiki=/,
        :match_details =>"Cookie match",
        :references => ["https://www.dokuwiki.org/dokuwiki"],
        :examples => ["https://docs.foxycart.com:443"],
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
