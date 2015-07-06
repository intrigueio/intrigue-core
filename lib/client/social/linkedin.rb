#require 'linkedin'
#require 'cgi'

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

=begin
# This class represents the linkedin API
#
# Reference:
# https://github.com/pengwynn/linkedin
#
class SearchService

  def initialize()
    api_key = Setting.where(:name => linkedin_api_key).first.value
    secret_key = Setting.where(:name => linkedin_secret_key).first.value

    @client = ::LinkedIn::Client.new(api_key, secret_key)
    @oauth_token = @client.request_token.token
    @oauth_secret = @client.request_token.secret
  end

  def get_authorize_uri
    # to test from your desktop, open the following url in your browser
    # and record the pin it gives you
    @client.request_token.authorize_url
  end

  # This is used to retrieve access keys when the user is given a pin
  def authorize_with_pin(pin)
    # then fetch your access keys
    access_keys = @client.authorize_from_request(@oauth_token, @oauth_secret, pin)

    # Store the keys for future use
    Setting.create({
      :name => "linkedin_access_key_1",
      :value => access_keys.first,
      :visible => false,
      :user_id => User.current.id })

    Setting.create({
      :name => "linkedin_access_key_2",
      :value => access_keys.first,
      :visible => false,
      :user_id => User.current.id })

  end

  # This is used to retrieve access keys after the user has verified access w/ pin
  def authorize_with_settings
    # then fetch your access keys

    access_key_1 = Setting.where(:name => "linkedin_access_key_1").first.value
    access_key_2 = Setting.where(:name => "linkedin_access_key_2").first.value

    access_keys = @client.authorize_from_access()
  end


  # Public: search for a string
  #
  # name: a search string
  # type: a symbol, one of... [:person, :company]
  #
  # Ruturns: An array of search results
  #
  def query(name, type)
    @client.search(name, type)
  end

end

# This class represents a corporation as returned by the Linkedin service.
class SearchResult

  attr_accessor :title

  def initialize
  end

  #
  #  Takes: A JSON search result
  #
  #  Returns: Nothing
  #
  def parse(result)
    @title = result['title']
  end

end
=end

end
end
end
