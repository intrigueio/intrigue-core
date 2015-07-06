require 'open-uri'
require 'nokogiri'

module Client
module Social
module Twitpic

  class WebClient < Client::Social::Base::WebClient

    def initialize
      @account_missing_strings = ["User not found"]
    end

    def generate_pretty_uri(username)
      "http://www.twitpic.com/photos/#{username}"
    end

    def generate_account_uri(username)
      "http://api.twitpic.com/2/users/show.json?username=#{username}"
    end
  end

end
end
end
