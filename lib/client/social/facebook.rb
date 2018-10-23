module Intrigue
module Client
module Social
module Facebook

  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["The link you followed may be broken, or the page may have been removed",
                                  "Sorry, this page isn't available"]
    end

    def generate_account_uri(username)
      "https://www.facebook.com/#{username}"
    end
  end

end
end
end
end