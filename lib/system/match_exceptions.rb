module Intrigue
module Core
module System
  module MatchExceptions

    def standard_ip_exceptions

      # incapsula: /107\.154\.*/

      # Akamai
      #  /^23\..*$/,
      #  /^2600:1400.*$/,
      #  /^2600:1409.*$/,

      # RFC1918
      #/^172\.16\..*$/||
      #/^192\.168\..*$/||
      #/^10\..*$/

      ip_exceptions = [
        /^127\..*$/,
        /^0.0.0.0$/,
        /(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)/, # check if we match 172.16.x.x
        /(^10\.)/, # check if we match 10.x.x.x
        /(^192\.168\.)/, # check if we match 192.168.x.x
        /(^fc00\:)/, # fc00::/7 address block = RFC 4193 Unique Local Addresses (ULA)
        /(^fec0\:)/ # fec0::/10 address block = deprecated (RFC 3879)
      ]
    end

    # this method matches entities to a static list of well-known non-traversable (er, unlikely to be our target)
    # entities. it'll return the regex that matches if it matches, otherwise,
    # it'll return false for a non-match
    #
    # if a skip_exception is provided, it'll be removed from the list. this is
    # key for situations when you've got a manually created domain that would
    # otherwise be an exception
    #
    # RETURNS A STRING (THE EXCEPTION) OR FALSE
    #
    def standard_no_traverse?(entity_name, type_string="Domain", skip_exceptions=[])

      out = false

      if type_string == "IpAddress"

        (standard_ip_exceptions - skip_exceptions).each do |exception|
          return exception if exception.match(entity_name)
        end

      elsif type_string == "Domain"

        ($standard_domain_exceptions - skip_exceptions).each do |exception|
          return exception if exception == entity_name
        end

      end

    out
    end
  end

end
end
end
