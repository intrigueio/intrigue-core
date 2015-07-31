class SearchBingTask < BaseTask

  def metadata
    { 
      :name => "search_bing",
      :pretty_name => "Search Bing",
      :authors => ["jcran"],
      :description => "This task hits the Bing API and finds related content. Discovered domains are created",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [{:type => "String", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","EmailAddress","PhoneNumber","WebAccount", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Make sure the key is set
    raise "API KEY MISSING: bing_api_key" unless $intrigue_config["bing_api_key"]

    entity_name = _get_entity_attribute "name"

    # Attach to the google service & search
    bing = Client::Search::Bing::SearchService.new($intrigue_config['bing_api_key'],50,'Web',{:Adult => 'Off'})

    results = bing.search(entity_name)
    results.first[:Web].each do |result|

      # a result will look like:
      #
      # {:__metadata=>
      # {:uri=>"https://api.datamarket.azure.com/Data.ashx/Bing/Search/v1/ExpandableSearchResultSet(guid'3033f6e3-d175-418c-a201-4a0c2c643384')/Web?$skip=0&$top=1", :type=>"WebResult"},
      # :ID=>"d30722c1-3fab-4ad6-90b1-aa136224afe4",
      # :Title=>"Speedtest.net by Ookla - The Global Broadband Speed Test",
      # :Description=>"Test your Internet connection bandwidth to locations around the world with this interactive broadband speed test from Ookla",
      # :DisplayUrl=>"www.speedtest.net",
      # :Url=>"http://www.speedtest.net/"}
      #

      ###
      ### SECURITY - take care, result might include malicious code?
      ###

      # Create the specific page
      _create_entity("Uri",     {     :name => result[:Url],
                                      :uri => result[:Url],
                                      :description => result[:Description],
                                      :title => result[:Title],
                                      :source => "Bing"
                                  })

      # Create a domain
      dns_name = result[:Url].split("/")[2]
      if Regexp.new(entity_name).match dns_name
        _create_entity("DnsRecord", { :name => dns_name })
      end

      ###
      ### XXX - this actually picks up a lot more than it should. Tighten
      ### this up when there are cycles. Thinking this needs to be stuck
      ### in a library somewhere too
      ###

      # Handle Twitter search results
      if result[:Url] =~ /https?:\/\/twitter.com\/.*$/
        account_name = result[:Url].split("/")[3]
        _create_entity("WebAccount", {
          :domain => "twitter.com",
          :name => account_name,
          :uri => "http://www.twitter.com/#{account_name}",
          :type => "full"
        })

      # Handle Facebook public profile  results
      elsif result[:Url] =~ /https?:\/\/www.facebook.com\/(public|pages)\/.*$/
        account_name = result[:Url].split("/")[4]
        _create_entity("WebAccount", {
          :domain => "facebook.com",
          :name => account_name,
          :uri => "#{result[:Url]}",
          :type => "public"
        })

      # Handle Facebook search results
      elsif result[:Url] =~ /https?:\/\/www.facebook.com\/.*$/
        account_name = result[:Url].split("/")[3]
        _create_entity("WebAccount", {
          :domain => "facebook.com",
          :name => account_name,
          :uri => "http://www.facebook.com/#{account_name}",
          :type => "full"
        })

      # Handle LinkedIn public profiles
      elsif result[:Url] =~ /^https?:\/\/www.linkedin.com\/in\/pub\/.*$/
          account_name = result[:Url].split("/")[5]
          _create_entity("WebAccount", {
            :domain => "linkedin.com",
            :name => account_name,
            :type => "public"
          })

      # Handle LinkedIn public directory search results
      elsif result[:Url] =~ /^https?:\/\/www.linkedin.com\/pub\/dir\/.*$/
        account_name = "#{result[:Url].split("/")[5]} #{result[:Url].split("/")[6]}"
        _create_entity("WebAccount", {
          :domain => "linkedin.com",
          :name => account_name,
          :uri  => result[:Url],
          :type => "public"
        })

      # Handle LinkedIn world-wide directory results
      elsif result[:Url] =~ /^http:\/\/[\w]*.linkedin.com\/pub\/.*$/

      # Parses these URIs:
      #  - http://za.linkedin.com/pub/some-one/36/57b/514
      #  - http://uk.linkedin.com/pub/some-one/78/8b/151

        account_name = result[:Url].split("/")[4]
        _create_entity("WebAccount", {
          :domain => "linkedin.com",
          :name => account_name,
          :uri => "#{result[:Url]}",
          :type => "public" })

      # Handle LinkedIn profile search results
      elsif result[:Url] =~ /^https?:\/\/www.linkedin.com\/in\/.*$/
        account_name = result[:Url].split("/")[4]
        _create_entity("WebAccount", {
          :domain => "linkedin.com",
          :name => account_name,
          :uri => "http://www.linkedin.com/in/#{account_name}",
          :type => "public" })

      # Handle Google Plus search results
      elsif result[:Url] =~ /https?:\/\/plus.google.com\/.*$/
        account_name = result[:Url].split("/")[3]
        _create_entity("WebAccount", {
          :domain => "google.com",
          :name => account_name,
          :uri => result[:Url],
          :type => "full" })

      # Handle Hackerone search results
      elsif result[:Url] =~ /https?:\/\/hackerone.com\/.*$/
        account_name = result[:Url].split("/")[3]
        _create_entity("WebAccount", {
          :domain => "hackerone.com",
          :name => account_name,
          :uri => result[:Url],
          :type => "full" }) unless account_name == "reports"

      # Check for Phone Number
      elsif result[:Description].match(/(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}/)

        # Grab all matches
        matches = result[:Description].scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4})/)
        matches.each do |match|
          _create_entity("PhoneNumber", { :name => "#{match[0]}" })
        end


      # Check for Email Address
      elsif result[:Description].match(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)

        # Grab all matches
        matches = result[:Description].scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4})/)
        matches.each do |match|
          _create_entity("EmailAddress", { :name => "#{match[0]}" })
        end

      end

    end # end results.each
  end # end run()

end # end Class
