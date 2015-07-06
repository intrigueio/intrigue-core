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

  class ApiClient

    def query(username)

      ###
      ### XXX = Api v1 no longer active.
      ###

      # Uses API v1
      #get_request "https://api.twitter.com/1/users/show/#{username}.json"

    end

  end

end
end
end
