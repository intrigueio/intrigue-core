module Intrigue
module Core
module System
  module MatchExceptions

    def standard_name_exceptions
      File.open("#{$intrigue_basedir}/data/standard_name_exceptions.list").readlines.map{|x| eval(x.strip) if x }
    end

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
        /^0.0.0.0$/
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

      elsif (type_string == "Domain" || type_string == "DnsRecord" || type_string == "Uri" )

        parsed_name = entity_name if type_string == "Domain"
        parsed_name = parse_domain_name(entity_name) if type_string == "DnsRecord"
        parsed_name = parse_domain_name(URI(entity_name).host) if type_string == "Uri"

        (standard_name_exceptions - skip_exceptions).each do |exception|
          if exception.match(".#{parsed_name}")
            return exception
          end
        end
      end

    out
    end
  end
  
end
end
end
