module Intrigue
module Ident
module Check
class Allegro < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Allegro",
        :product => "RomPager",
        :version => nil,
        :dynamic_version => lambda { |x|
          _first_header_capture(x,/Allegro-Software-RomPager\/(.*)$/i)
        },
        :examples => [ "http://120.127.142.126" ],
        :match_type => :content_headers,
        :match_content =>  /server:\ Allegro-Software-RomPager/,
        :match_details =>"server header",
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
