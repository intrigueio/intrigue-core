###
### Code originated from Julien Sobrier's excellent safebrowsing client:
###   https://github.com/juliensobrier/google-safe-browsing-lookup-ruby
###

# Author:: Julien Sobrier (mailto:julien@sobrier.net)
# Copyright:: Copyright (c) 2015 Julien Sobrier
# License:: Distributes under the same terms as Ruby

require 'uri'
require 'net/https'
module Intrigue
module Client
module Search
module Google

class SafebrowsingLookup
  # API key
  attr_reader :key
  # Enable debug & error output to the standard output
  attr_reader :debug
  # Enable error output to the standard output
  attr_reader :error
  # Contain last error
  attr_reader :last_error
  # Library version
  attr_reader :version
  # Google API version
  attr_reader :api_version

  # New client
  #
  # +key+:: API key
  # +debug+:: Set to true to print debug & error output to the standard output. false (disabled) by default.
  # +error+:: Set to true to print error output to the standard output. false (disabled) by default.
  def initialize(key='', debug=false, error=false)
    @key = key || ''
    @debug = debug || false
    @error = error || false
    @last_error = ''

    @version = '0.2'
    @api_version = '3.1'


    raise ArgumentError, "Missing API key" if (@key == '')
  end

  # Lookup a list of URLs against the Google Safe Browsing v2 lists.
  #
  # Returns a hash <url>: <Gooogle match>. The possible values for <Gooogle match> are: "ok" (no match), "malware", "phishing", "malware,phishing" (match both lists) and "error".
  #
  # +urls+:: List of URLs to lookup. The Lookup API allows only 10,000 URL checks a day. If you need more, find a Ruby implementation of the full Google Safe Browsing v2 API. Each requests must contain 500 URLs at most. The lookup() method will split the list of URLS in blocks of 500 URLs if needed.
  def lookup(urls='')
    if (urls.respond_to?('each') == false)
      urls = Array.new(1, urls)
    end
#     urls_copy = Array.new(urls)

    results = { }

#     while (urls_copy.length > 0)
#       inputs = urls_copy.slice!(0, 500)
    count = 0
    while (count * 500 < urls.length)
      inputs = urls.slice(count * 500, 500)
      body = inputs.length.to_s
      inputs.each do |url|
        puts "URL: #{url}"
        puts "CANONICAL #{canonical(url)}"
        body = body + "\n" + canonical(url)

      end

      debug("BODY:\n#{body}\n\n")
      uri = URI.parse("https://sb-ssl.google.com/safebrowsing/api/lookup?client=ruby&key=#{@key}&appver=#{@version}&pver=#{@api_version}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 30
      http.read_timeout = 30
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = http.request_post("#{uri.path}?#{uri.query}", body)

      case response
        when Net::HTTPOK # 200
          debug("At least 1 match\n")
          results.merge!( parse(inputs, response.body_utf8) )

        when Net::HTTPNoContent # 204
          debug("No match\n")
          results.merge!( ok(inputs) )

        when Net::HTTPBadRequest # 400
          error("Invalid request")
          results.merge( errors(inputs) )

        when Net::HTTPUnauthorized # 401
          error("Invalid API key")
          results.merge!( errors(inputs) )

        when Net::HTTPServiceUnavailable # 503
          error("Server error, client may have sent too many requests")
          results.merge!( errors(inputs) )

        else
          self.error("Unexpected server response: #{response.code}")
          results.merge!( errors(inputs) )
      end

    count = count + 1
    end

    return results
  end


  private

  # Not much is actually done, full URL canonicalization is not required with the Lookup library according to the API documentation
  def canonical(url='')
    # remove leading/ending white spaces
    url.strip!

    # make sure whe have a scheme
    if (url !~ /^https?\:\/\//i)
      url = "http://#{url}"
    end

    uri = URI.parse(url)

    return uri.to_s
  end


  def parse(urls=[], response)
    lines = response.split("\n")

    if (urls.length != lines.length)
      error("Number of URLs in the reponse does not match the number of URLs in the request")
      debug("#{urls.length} / #{lines.length}")
      debug(response);
      return errors(urls);
    end

    results = { }
    for i in (0..lines.length - 1)
      results[urls[i]] = lines[i]
      debug(urls[i] + " => " + lines[i])
    end

    return results
  end


  def errors(urls=[])
    return Hash[*urls.map {|url| [url, 'error']}.flatten]
  end

  def ok(urls=[])
    return Hash[*urls.map {|url| [url, 'ok']}.flatten]
  end


  def debug(message='')
    puts message if (@debug == true)
  end


  def error(message='')
    puts "#{message}\n" if (@debug == true or @error == true)
    @last_error = message
  end

end

end
end
end
end