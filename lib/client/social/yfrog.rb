module Client
module Social
module Yfrog
  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["Something went wrong"]
    end

    def generate_account_uri(username)
      "https://yfrog.com/user/#{username}/profile"
    end

  end
end
end
end
