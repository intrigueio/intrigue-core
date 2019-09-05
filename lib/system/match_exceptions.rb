module Intrigue
module System
module MatchExceptions

  # Method gives us a true/false, depending on whether the entity is in an
  # exception list. Currently only used on project, but could be included
  # in task_result or scan_result. Note that they'd need the "additional_exception_list"
  # and "use_standard_exceptions" fields on the object
  def exception_entity?(entity_name, type_string=nil, skip_regexes)

    # SEED ENTITY, CANT BE AN EXCEPTION
    if seed_entity?(type_string,entity_name)
      return false
    end

    # Check standard exceptions first
    # (which now reside in Intrigue::TraverseExceptions)
    if non_traversable?(entity_name,type_string, skip_regexes)
      return true
    end

    # if we don't have a list, safe to return false now, otherwise proceed to additional exceptions
    # which are provided as an attribute on the object
    return false unless additional_exception_list && !additional_exception_list.empty?

    # check additional exception strings
    is_an_exception = false
    additional_exception_list.each do |x|
      # this needs two cases:
      # 1) case where we're an EXACT match (ey.com)
      # 2) case where we're a subdomain of an exception domain (x.ey.com)
      # neither of these cases should match the case: jcpenney.com
      if entity_name.downcase =~ /^#{Regexp.escape(x.downcase)}(:[0-9]*)?$/ ||
        entity_name.downcase =~ /^.*\.#{Regexp.escape(x.downcase)}(:[0-9]*)?$/
        return true
      end
    end

  false
  end

  def standard_name_exceptions
    File.open("#{$intrigue_basedir}/data/standard_name_exceptions.list").readlines.map{|x| Regexp.new x if x }
  end

  def standard_ip_exceptions

    # incapsula: /107\.154\.*/

    # RFC1918
    #/^172\.16\..*$/||
    #/^192\.168\..*$/||
    #/^10\..*$/

    ip_exceptions = [
      /^23\..*$/,
      /^2600:1400.*$/,
      /^2600:1409.*$/,
      /^127\..*$/,
      /^0.0.0.0$/
    ]
  end

  # this method matches entities to a static list of known-non-traversable
  # entities. it'll return the regex that matches if it matches, otherwise,
  # it'll return false for a non-match
  #
  # if a skip_exception is provided, it'll be removed from the list. this is
  # key for situations when you've got a manually created domain that would
  # otherwise be an exception
  #
  # RETURNS A REGEX OR FALSE
  #
  def non_traversable?(entity_name, type_string="Domain", skip_exceptions=[])

    if type_string == "IpAddress"

      (standard_ip_exceptions - skip_exceptions).each do |exception|
        return exception if (entity_name =~ exception)
      end

    elsif (type_string == "Domain" || type_string == "DnsRecord" || type_string == "Uri" )

      (standard_name_exceptions - skip_exceptions).each do |exception|
        return exception if (entity_name =~ exception ||  ".#{entity_name}" =~ exception)
      end

    end

  false
  end

end
end
end
