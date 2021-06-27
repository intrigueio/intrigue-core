module Intrigue
  module Issue
    class F5BigIpUnencryptedCookie < BaseIssue

      # MSF-sourced functionality credit:
      # 'Thanat0s <thanspam[at]trollprod.org>',
      # 'Oleg Broslavsky <ovbroslavsky[at]gmail.com>',
      # 'Nikita Oleksov <neoleksov[at]gmail.com>',
      # 'Denis Kolegov <dnkolegov[at]gmail.com>'

      def self.generate(instance_details={})
      {
        added: "2021-03-04",
        name: "f5_bigip_unencrypted_cookie",
        pretty_name: "F5 BigIP Unencrypted Cookie",
        severity: 4,
        category: "misconfiguration",
        status: "confirmed",
        description: "Decodes a F5 BigIP Cookie in order to leak information about the backend such as the Pool Name, IP Address, and Port.",
        references: [
          { type: "description", uri: "http://support.f5.com/kb/en-us/solutions/public/6000/900/sol6917.html" },
          { type: "description", uri: "http://support.f5.com/kb/en-us/solutions/public/7000/700/sol7784.html?sr=14607726" }
        ],
        affected_software: [
          { :vendor => "F5", :product => "BIG-IP Configuration Utility" },
          { :vendor => "F5", :product => "BIG-IP Access Policy Manager" },
          { :vendor => "F5", :product => "BIG-IP Application Security Manager" },
          { :vendor => "F5", :product => "BIG-IP Local Traffic Manager" }
        ],
        authors: ["maxim", "jcran", "jhawthorn"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class F5BigIpUnencryptedCookie < BaseCheck

      def self.check_metadata
        { allowed_types: ["Uri"] }
      end

      ## Cookies to match
      ##
      ## Get the SLB session IDs for all cases:
      ## 1. IPv4 pool members - "BIGipServerWEB=2263487148.3013.0000",
      ## 2. IPv4 pool members in non-default routed domains - "BIGipServerWEB=rd5o00000000000000000000ffffc0000201o80",
      ## 3. IPv6 pool members - "BIGipServerWEB=vi20010112000000000000000000000030.20480",
      ## 4. IPv6 pool members in non-default route domains - "BIGipServerWEB=rd3o20010112000000000000000000000030o80"
      ##
      ##  regexp = /
      ##    ([~_\.\-\w\d]+)=(((?:\d+\.){2}\d+)|
      ##    (rd\d+o0{20}f{4}\w+o\d{1,5})|
      ##    (vi([a-f0-9]{32})\.(\d{1,5}))|
      ##    (rd\d+o([a-f0-9]{32})o(\d{1,5})))
      ##    (?:$|,|;|\s)
      ##  /x
      ##

      ## Modified version of MSF function
      def bigip_cookie_decode(cookie_value)

        if cookie_value =~ /(\d{8,10})\.(\d{1,5})\./
          ip_address = Regexp.last_match(1).to_i
          port = Regexp.last_match(2).to_i
          ip_address = change_endianness(ip_address)
          ip_address = addr_itoa(ip_address)
          port = change_endianness(port, 2)
        elsif cookie_value.downcase =~ /rd\d+o0{20}f{4}([a-f0-9]{8})o(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address)
        elsif cookie_value.downcase =~ /vi([a-f0-9]{32})\.(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address, true)
          port = change_endianness(port, 2)
        elsif cookie_value.downcase =~ /rd\d+o([a-f0-9]{32})o(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address, true)
        else
          return nil
        end

        {
          poolname: cookie_value.match(/BIGipServer(.+?)=/i).captures.first,
          ip_address: ip_address,
          port: port
        }
      end

      def check

        uri = _get_entity_name

        decoded_cookies = []

        10.times do |i| # send 10 requests as each request may return a decoded cookie with a different ip address

          # cookie was not found in the second request; stop sending additional requests & exhaust the loop
          next if i > 1 && decoded_cookies.compact.empty?

          response = http_request :get, uri

          # grab the cookie in a case-insensitive way, but we're not yet sure we have a bigipserver cookie
          set_cookie_header = response.headers.select{|x,y| x.downcase  == "set-cookie" }

          unless !set_cookie_header.empty?
            _log_error "Missing a set-cookie header, failing"
            return
          end

          # okay we got one, grab our cookie by accessing by our key
          #   (which may/may not have been lowercase - handled above)
          #
          # Since we could get a string or an array back, make sure it's a single array
          # by forcing and calling flatten
          #
          key = set_cookie_header.keys.first
          set_cookie = [set_cookie_header[key]].flatten if key

          # we have cooooooookiees!!!
          if set_cookie

            # find will only return only one item so we definitely have a string
            cookie_string = set_cookie.find{|x| x =~ /BIGipServer/i }
            _log_error "We have cookies, but nothing that looks like a BIGIP cookie" unless cookie_string

            # grab our specific bigip cookie out of the string
            bigip_cookie_string = "#{cookie_string}".split(';').find{ |c| c =~ /BIGipServer(.*)=/i }
            _log_error "Unable to extract BIGIP cookie!" unless bigip_cookie_string

            # decode it, and save into our array of results
            decoded_cookies << bigip_cookie_decode(bigip_cookie_string) if bigip_cookie_string

          else
            _log_error "No cookies set!!"
          end

        end

        # create IP Address entities & Hostname Entity from the cookie
        return false if decoded_cookies.compact.empty?

        # create ip addresses if we have anything
        decoded_cookies.compact.each do |d|
          next unless d[:ip_address]
          _create_entity 'IpAddress', 'name' => d[:ip_address], 'f5_cookie_info_leak' => d
        end

      # return decoded cookies array as proof
      { decoded_cookies: decoded_cookies.compact.uniq }
      end

    end
  end
end
