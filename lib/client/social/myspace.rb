
module Intrigue
module Client
module Social
module Myspace
  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings =["we can't find the page you're looking for."]
    end

    def generate_account_uri(username)
      "https://myspace.com/#{username}"
    end

  end
end
end
end
end