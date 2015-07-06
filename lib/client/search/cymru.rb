require 'resolv'
require 'ipaddr'

###
### Code based on the 'cymruwhois' gem by @junv:
###    https://github.com/junv/cymruwhois
###

module Client
module Search
module Cymru

  module DnsQuery
    def intxt(name)
      dns = Resolv::DNS.new
      begin
        ans = dns.getresource(name, Resolv::DNS::Resource::IN::TXT)
      rescue Resolv::ResolvError
        return arr = "0|0.0.0.0|CC|NIC|Date".split('|').map {|e| e.upcase.strip}
      end
      arr = ans.data.split('|').map {|e| e.upcase.strip}
    end
  end

  class IPAddress
    include DnsQuery
    private :intxt

    attr_reader :asnum, :cidr, :country, :registry, :allocdate, :asname

    ORIGIN = "origin.asn.cymru.com"
    ORIGIN6 = "origin6.asn.cymru.com"
    BOGON = "bogons.cymru.com"

    def whois(addr)
      ip = IPAddr.new(addr)
      if ip.ipv4?
        revdns = ip.reverse.sub("in-addr.arpa", ORIGIN)
      elsif ip.ipv6?
        revdns = ip.reverse.sub("ip6.arpa", ORIGIN6)
      end

      ansip = intxt(revdns)
      @asnum = ansip[0]
      @cidr = ansip[1]
      @country = ansip[2]
      @registry = ansip[3]
      @allocdate = ansip[4]

      # to address the multi ASN issue for the same IP Block
      asparam = ansip[0].split

      ansasnum = ASNumber.new
      ansasnum.whois(asparam[0])
      @asname = ansasnum.asname

      ansip << @asname
    end
    alias :lookup :whois

  end

  class ASNumber
    include DnsQuery
    private :intxt

    attr_reader :country, :registry, :allocdate, :asname

    ASN = ".asn.cymru.com"

    def initialize
    end

    def whois(asn)
      @asn = "AS" + asn + ASN

      ans = intxt(@asn)
      @country = ans[1]
      @registry = ans[2]
      @allocdate = ans[3]
      @asname = ans[4]

      return ans
    end
    alias :lookup :whois

  end

end
end
end
