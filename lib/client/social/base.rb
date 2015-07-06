require 'nokogiri'
require 'open-uri'

###
### Base class for all the social-related services. These classes
### may have a WebClient and an ApiClient for querying information
### about persons or accounts on the specific platform.
###
### All "social" classes will inherit methods from this base class.
###

module Client
module Social
module Base

  class WebClient


    include Task::Web
    #
    # This methods requests a specified URI and greps for strings which indicate that an
    # account (doesn't) exist.
    #
    def check_account_exists(username)
      begin

        #
        # Request the uri specified as holding the account
        #
        account_uri = generate_account_uri(username)
        body = http_get_body account_uri

        #
        # It's possible we won't get a valid response back from
        # the request
        #
        # XXX - probably better to deal with this in the http_get_body call
        #
        return false unless body

        #
        # Check for each string that may indicate we didn't find the account
        #
        @account_missing_strings.each do |account_missing_string|
          if body.include? account_missing_string
            return false
          end
        end

      #
      # Rescue in the case of a 404 or a redirect
      #
      # TODO - this should really log into the task?
      #rescue OpenURI::HTTPError => e
        #TapirLogger.instance.log "Error, couldn't open #{self.check_account_uri_for(account_name)}"
      #  return false
      #rescue RuntimeError => e
        #TapirLogger.instance.log "Redirection? #{e}"
        #return false
      end

      #
      # Otherwise, lets assume it exists (TODO - this will return true if we don't have
      # any @account_missing_strings - might make sense to make this a little more complicated.
      #
      true
    end

    def generate_account_uri(username)
      raise "Must override"
    end

    def generate_pretty_uri(username)
      generate_account_uri(username) # default to the same uri as where we query the account info
    end
  end

end
end
end
