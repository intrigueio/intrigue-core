module Intrigue
  module Task
    module UriHelper
      require 'uri'
      require 'ipaddr'

      def valid_ip?(ip)
        ip_addr = IPAddr.new ip
        ip_addr.ipv4? || ip_addr.ipv6?
      rescue IPAddr::InvalidAddressError => e
        _log_error "#{ip} Seems to be an invalid IP Address #{e}"
        false
      rescue StandardError => e
        _log_error "#{ip} Seems to be an invalid IP Address #{e}"
        false
      end

      def get_host_from_ip(address)
        return address if valid_ip?(address)

        url = URI.parse(address)

        ip_to_test = if !url.host.nil?
                       url.host.to_s
                     else
                       url.to_s
                     end

        return nil unless valid_ip?(ip_to_test)

        ip_to_test
      rescue StandardError => e
        _log_error "Unable to parse '#{address}' URL: #{e}"
        nil
      end
    end
  end
end
