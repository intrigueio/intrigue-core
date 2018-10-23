module Intrigue
module Client
module Social
module Foursquare

  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["We couldn't find the page you're looking for."]
    end

    def generate_account_uri(username)
      "https://www.foursquare.com/#{username}"
    end

  end

end
end
end
end