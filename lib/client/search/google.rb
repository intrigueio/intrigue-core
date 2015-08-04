require 'googleajax'

module Client
module Search
module Google

  class SearchScraper

    include Intrigue::Task::Web

    def search(search_string,pages=5)
      count = 5
      responses = []

      pages.times do |x|
        uri = "http://www.google.com/search??hl=en&lr=&ie=UTF-8&q=#{search_string}&filter=0&sa=N&start=#{pages*count}&num=100"
        responses << http_get_body(uri)
      end

    responses
    end
  end

=begin
      ############################
      # DEPENDENCIES:
      #
      # Install the capybara gem:
      # $ gem install capybara
      #
      # Then, follow instructions from https://github.com/thoughtbot/capybara-webkit#readme
      # and install the capybara-webkit gem and drivers:
      # $ sudo apt-get install libqt4-dev
      # $ gem install capybara-webkit
      ############################

      class SearchScraper
      include Capybara::DSL

      def initialize
      Capybara.run_server = false
      Capybara.default_selector = :xpath
      Capybara.current_driver = :webkit
      Capybara.default_wait_time = 20

      # Uncomment to capybara-webkit scraping
      # Capybara.current_driver = :selenium ->
      # Capybara.current_driver = :webkit

      Capybara.app_host = "http://www.google.com"
      end

      def search(term)

      uris = []

      #begin
      visit('/')
      fill_in "q", :with => term
      click_button "gbqfb"
      results = all("//li/div/h3/a")
      results.each { |r| uris << r[:href]}
      #rescue Capybara::DriverNotFoundError
      # TODO - should we raise an error here?
      #  uris << "ERROR: Unable to Scrape"
      #end

      uris
      end
      end
=end

  # This class represents the google AJAX API
  #
  # Reference:
  # * http://chris.mowforth.com/google-ajax-search-api-ruby-0
  #
  class SearchService

    def initialize
      GoogleAjax.referrer = "localhost"
      #GoogleAjax.api_key = ApiKeys.instance.keys['google_ajax_key']
    end

    #
    # Takes: a search string
    #
    # Ruturns: An array of search results
    #
    def search(search_string)
      GoogleAjax::Search.web(search_string)[:results]
    end
  end

  # This class represents a searchresult.
  class SearchResult

    attr_accessor :gsearch_result_class
    attr_accessor :unescaped_url
    attr_accessor :url
    attr_accessor :visible_url
    attr_accessor :cached_url
    attr_accessor :title
    attr_accessor :title_no_formatting
    attr_accessor :content

    def initialize
    end

    #
    #  Takes: A JSON search result
    #
    #  Returns: Nothing
    #
    def parse_json(result)
      @gsearch_result_class = result['GsearchResultClass']
      @unescaped_url = result['unescapedUrl']
      @url = result['url']
      @visible_url = result['visibleUrl']
      @cached_url = result['cacheUrl']
      @title = result['title']
      @title_no_formatting = result['titleNoFormatting']
      @content = result['content']
    end

    def to_s
      "#{@gsearch_result_class} #{@title} #{@url} #{@content}"
    end

  end

end
end
end
