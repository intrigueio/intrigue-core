module Intrigue
  module Task
    class F5BigIpCookieDecoder < BaseTask

      # MSF-provided Functionality credit: 
      # 'Thanat0s <thanspam[at]trollprod.org>',
      # 'Oleg Broslavsky <ovbroslavsky[at]gmail.com>',
      # 'Nikita Oleksov <neoleksov[at]gmail.com>',
      # 'Denis Kolegov <dnkolegov[at]gmail.com>'

      def self.metadata
        {
          :name => "f5_bigip_cookie_decoder",
          :pretty_name => "F5 BigIP Cookie Decoder",
          :authors => ["jcran", "jhawthorn", "maxim"],
          :description => "Decodes a F5 BigIP Cookie in order to leak information about the backend such as the Pool Name, IP Address, and Port.",
          :references => [
            "http://support.f5.com/kb/en-us/solutions/public/6000/900/sol6917.html",
            "http://support.f5.com/kb/en-us/solutions/public/7000/700/sol7784.html?sr=14607726"
          ],
          :type => "discovery",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [
            {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
          ],
          :allowed_options => [],
          :created_types => ["IpAddress"]
        }
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
        decoded = {}
        case
        when cookie_value =~ /(\d{8,10})\.(\d{1,5})\./
          ip_address = Regexp.last_match(1).to_i
          port = Regexp.last_match(2).to_i
          ip_address = change_endianness(ip_address)
          ip_address = addr_itoa(ip_address)
          port = change_endianness(port, 2)
        when cookie_value.downcase =~ /rd\d+o0{20}f{4}([a-f0-9]{8})o(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address)
        when cookie_value.downcase =~ /vi([a-f0-9]{32})\.(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address, true)
          port = change_endianness(port, 2)
        when cookie_value.downcase =~ /rd\d+o([a-f0-9]{32})o(\d{1,5})/
          ip_address = Regexp.last_match(1).to_i(16)
          port = Regexp.last_match(2).to_i
          ip_address = addr_itoa(ip_address, true)
        else
          ip_address = nil
          port = nil
        end

        # decoded[:hostname] = cookie_value.match(/BIGipServer(.*)=/i).captures.first
        decoded[:poolname] = cookie_value.match(/BIGipServer(.*)=/i).captures.first
        decoded[:ip_address] = ip_address.nil? ? nil : ip_address
        decoded[:port] = port.nil? ? nil : port
        decoded
      end

      def run
        super

        uri = _get_entity_name

        decoded_cookies = []

        10.times do |i| # send 10 requests as each request may return a decoded cookie with a different ip address
          # cookie was not found in the second request ; stop sending additional requests & exhaust the loop
          next if i > 1 && decoded_cookies.empty?

          response = http_request :get, uri
          set_cookie = response.headers['set-cookie']

          unless set_cookie.nil?
            # if multiple cookies are returned in response - extract the bipipserver cookie
            set_cookie = set_cookie.select { |c| c =~ /BIGipServer(.*)=/i }.first if set_cookie.is_a?(Array)
            return nil if set_cookie.empty?

            cookie = set_cookie.split(';').select { |c| c =~ /BIGipServer(.*)=/i }.first # only one cookie so its a string
          end

          decoded_cookies << bigip_cookie_decode(cookie) if cookie
        end
        # create IP Address entities & Hostname Entity from the cookie
        create_issue_entities decoded_cookies.uniq unless decoded_cookies.empty?
      end

      ##
      # creates the linked issue + entities
      def create_issue_entities(decoded_arr)
        _create_linked_issue 'f5_bigip_cookie_decoder', 'Decoded Cookie' => decoded_arr

        decoded_arr.each do |d|
          _create_entity 'IpAddress', 'name' => d[:ip_address]
        end
      end

    end
  end
end
