module Intrigue
module Ident
module Check
class Axway < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Axway",
        :product =>"SecureTransport",
        :references => ["https://www-356.ibm.com/partnerworld/gsd/solutiondetails.do?&solution=47052"],
        :version => nil,
        :dynamic_version => lambda {|x| _first_header_capture(x,/SecureTransport (.*) (build:.*)/)},
        :match_type => :content_headers,
        :match_content =>  /server: SecureTransport/i,
        :match_details =>"server header - build is avail too",
        :examples => ["https://dhebpcb01.boulder.ibm.com:443"],
        :verify => ["xaWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovL2RoZWJwY2IwMS5ib3VsZGVyLmlibS5jb206NDQz"],
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
