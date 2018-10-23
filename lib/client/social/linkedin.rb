#require 'linkedin'
#require 'cgi'
module Intrigue
module Client
module Social
module Linkedin

  class WebClient < Client::Social::Base::WebClient
    def initialize
      @account_missing_strings = ["The requested URL was not found on this server"]
    end

    def generate_account_uri(username)
      "http://www.linkedin.com/in/#{username}"
    end
  end

  class WebDirectoryClient < Client::Social::Base::WebClient
    def initialize
      @account_missing_strings = ["could not be found"]
    end

    def generate_account_uri(first_name, last_name)
      "http://www.linkedin.com/pub/dir/#{first_name}/#{last_name}"
    end
  end

  class Scraper
    def scrape(username)
    end
  end

  class Profile
    def initialize
    end
  end

end
end
end
end