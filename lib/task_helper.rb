require "uri"

module TaskHelper

  ###
  ### Expects generic content
  ###
  def parse_content_for_entities(content)
    parse_links(content)
    parse_strings(content)
    parse_seals(content)
  end

  def parse_links(content)
    URI::extract(content).each do |link|
      _create_entity("Uri", {:name => "#{link}" }) if "#{link}" =~ /^http/
    end
  end

  ###
  ### Expects a webpage's contents
  ###
  def parse_strings(content)

    # Scan for email addresses
    addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
    addrs.each do |addr|
      _create_entity("EmailAddress", {:name => addr})
    end

    # Scan for dns records
    dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
    dns_records.each do |dns_record|
      _create_entity("DnsRecord", {:name => addr})
    end

    # Scan for interesting content
    list = content.scan(/upload/im)
    list.each do |item|
      _create_entity("Info", {:name => "File upload on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/admin/im)
    list.each do |item|
      _create_entity("Info", {:name => "Admin mention on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/password/im)
    list.each do |item|
      _create_entity("Info", {:name => "Password mention on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/<form/im)
    list.each do |item|
      _create_entity("Info", {:name => "Form on #{_get_entity_attribute "name"}"})
    end

  end

  ###
  ### Expects a webpage
  ###
  def parse_seals(content)

    #
    # Trustwave Seal
    #
    content.scan(/sealserver.trustwave.com\/seal.js/i).each do |item|
      _create_entity("Info", {:name => "SecuritySeal: Trustwave #{_get_entity_attribute "name"}"})
    end

  end

end
