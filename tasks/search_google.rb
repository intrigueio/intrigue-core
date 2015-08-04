module Intrigue
class SearchGoogleTask < BaseTask

  def metadata
    {
      :name => "search_google",
      :pretty_name => "Search Google",
      :authors => ["jcran"],
      :description => "This task hits the Google API and finds related content. Discovered domains are created",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [{:type => "String", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord", "WebAccount","Uri"]
    }
  end

  ###
  ### XXX - Transition this to web accounts?
  ###

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_attribute "name"

    # Attach to the google service & search
    results = Client::Search::Google::SearchService.new.search(entity_name)

    results.each do |result|

      # Create a domain
      _create_entity "DnsRecord", :name => result[:visible_url]

      # Create the associated top-level domain
      _create_entity "DnsRecord", :name => result[:visible_url].split(".").last(2).join(".")

      # Handle Twitter search results
      if result[:title_no_formatting] =~ /Twitter/
        account_name = result[:title_no_formatting].scan(/\(.*\)/).first[2..-2]
        _create_entity("WebAccount", {
          :name => account_name,
          :domain => "twitter.com",
          :uri => "http://www.twitter.com/#{account_name}" })

      # Handle Facebook search results
      elsif result[:unescaped_url] =~ /https:\/\/www.facebook.com/
        account_name = result[:unescaped_url].scan(/[^\/]+$/).first
        _create_entity("WebAccount", {
          :name => account_name,
          :domain => "facebook.com",
          :uri => "http://www.facebook.com/#{account_name}" })

      # Handle LinkedIn search results
      elsif result[:unescaped_url] =~ /http:\/\/www.linkedin.com\/in/
        account_name = result[:unescaped_url].scan(/[^\/]+$/).first
        _create_entity("WebAccount", {
          :name => account_name,
          :domain =>"linkedin.com",
          :uri => "http//www.linkedin.com/in/#{account_name}" })

      # Otherwise, just create a generic search result

      ###
      ### SECURITY - take care, result[:content] might include malicious code
      ###
      else
        _create_entity("Uri", {
          :name => result[:unescaped_url],
          :uri => result[:unescaped_url],
          :content => Rack::Utils.escape_html(result[:content])
        })
      end

    end # end results.each
  end # end run()

end # end Class
end
