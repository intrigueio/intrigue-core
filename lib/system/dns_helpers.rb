module Intrigue
module Core
module System
  module DnsHelpers

    ### Parse out a domain, given a domain or dns record.
    ###
    def parse_domain_name(record)

      # sanity check
      return nil unless record 
      return nil if record.is_ip_address?

      # try to parse a tld and if we can't parse out a tld, 
      # just keep going with the base record
      parsed_record_tld = parse_tld(record)
      return nil unless parsed_record_tld 

      split_tld = parsed_record_tld.split(".")
      if (split_tld.last == "com" || split_tld.last == "net") && split_tld.count > 1 # handle cases like amazonaws.com, netlify.com
        length = split_tld.count
      else
        length = split_tld.count + 1
      end
      
    record.split(".").last(length).join(".")
    end

    ### This helper parses out a tld, given a domain or dnsrecord. handy
    ### in many contexts 
    ###
    # assumes we get a dns name of arbitrary length
    def parse_tld(record)
      return nil unless record

      # first check if we're not long enough to split, just returning the domain
      return nil if record && record.split(".").length < 2

      # Make sure we're comparing bananas to bananas
      record = "#{record}".downcase

      # now one at a time, check all known TLDs and match
      begin
        raw_suffix_list = File.open("#{$intrigue_basedir}/data/public_suffix_list.clean.txt").read.split("\n")
        suffix_list = raw_suffix_list.map{|l| "#{l.downcase}".strip }

        # first find all matches
        matches = []
        suffix_list.each do |s|
          if record =~ /\.#{Regexp.escape(s.strip)}$/i # we have a match ..
            matches << s.strip
          end
        end

        # then find the longest match
        if matches.count > 0
          longest_match = matches.sort_by{|x| x.split(".").length + x.split(".").last.length }.last
          return longest_match
        end

      rescue Errno::ENOENT => e
        _log_error "Unable to locate public suffix list, failing to check / create domain for #{lookup_name}"
        return nil
      end

    # unknown tld
    nil
    end


  end
end
end
end