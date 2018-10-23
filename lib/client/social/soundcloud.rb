module Intrigue
module Client
module Social
module Soundcloud
 class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["Oops, looks like we can't find that page!", "Whoa, something went wrong and it wasn't supposed to happen."]
    end

    def generate_account_uri(username)
      "http://www.soundcloud.com/#{username}"
    end

  end
end
end
end
end