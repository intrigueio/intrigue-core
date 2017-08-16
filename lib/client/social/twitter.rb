module Client
module Social
module Twitter
  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["Sorry, that page"]
    end

    def generate_account_uri(username)
      "https://twitter.com/#{username}"
    end

  end

end
end
end
