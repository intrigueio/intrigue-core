module Intrigue
module Core
module System
  module DnsHelpers

    ###
    ### TODO ... system helper 
    ###
    def parse_domain_name(record)
      return nil unless record 
      split_tld = parse_tld(record).split(".")
      if (split_tld.last == "com" || split_tld.last == "net") && split_tld.count > 1 # handle cases like amazonaws.com, netlify.com
        length = split_tld.count
      else
        length = split_tld.count + 1
      end
      
    record.split(".").last(length).join(".")
    end


    ###
    ### TODO ... system helper 
    ###
    # assumes we get a dns name of arbitrary length
    def parse_tld(record)
      return nil unless record

      # first check if we're not long enough to split, just returning the domain
      return record if record && record.split(".").length < 2

      # Make sure we're comparing bananas to bananas
      record = "#{record}".downcase

      # now one at a time, check all known TLDs and match
      begin
        raw_suffix_list = File.open("#{$intrigue_basedir}/data/public_suffix_list.clean.txt").read.split("\n")
        suffix_list = raw_suffix_list.map{|l| "#{l.downcase}".strip }

        # first find all matches
        matches = []
        suffix_list.each do |s|
          if record =~ /.*#{Regexp.escape(s.strip)}$/i # we have a match ..
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
    record
    end


  end
end
end
end