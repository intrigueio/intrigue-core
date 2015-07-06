module Client
module Social
module Soundcloud
 class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["Oops, looks like we can't find that page!", "Whoa, something went wrong and it wasn't supposed to happen."]
    end

    def generate_pretty_uri(username)
        "http://www.soundcloud.com/#{username}"
    end

    def generate_account_uri(username)
      "http://m.soundcloud.com/_api/resolve?url=http://soundcloud.com/#{username}&client_id=2Kf29hhC5mgWf62708A&format=json"
    end

  end
end
end
end
