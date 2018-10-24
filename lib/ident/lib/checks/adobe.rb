module Intrigue
module Ident
module Check
class Adobe < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "application",
        :vendor => "Adobe",
        :product => "Coldfusion",
        :version => nil,
        :match_type => :content_cookies,
        :match_content => /CFTOKEN=/,
        :match_details => "Adobe Coldfusion Cookie Match",
        :hide => false,
        :examples => ["https://209.235.70.106:443"],
        :paths => ["#{url}"]
      },
      {
        :type => "application",
        :vendor => "Adobe",
        :product => "Experience Manager",
        :version => nil,
        :match_type => :content_body,
        :match_content => /AEM/,
        :match_details => "Adobe Experience Manager",
        :hide => false,
        :examples => ["https://www.ford.com/content/dam/login/core/content/login"],
        :paths => ["#{url}/libs/granite/core/content/login.html"]
      }

    ]
  end
end
end
end
end
