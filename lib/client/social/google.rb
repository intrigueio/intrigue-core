#require "capybara"
#require "capybara/dsl"
require "googleajax"
module Intrigue
module Client
module Social
module Google

  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["The requested URL was not found on this server"]
    end

    def generate_account_uri(username)
      "https://profiles.google.com/u/0/#{username}/about"
    end

  end


end
end
end
end