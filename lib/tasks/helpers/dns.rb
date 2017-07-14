require 'dnsruby'

module Intrigue
  module Task
    module Dns

      def resolve_ip(lookup_name)

        begin
          _log "Resolving #{lookup_name}"
          resolver = Dnsruby::Resolver.new(:search => [])
          result = resolver.query(lookup_name, Dnsruby::Types::ANY)

          # Let us know if we got an empty result
          return if result.answer.empty?

          ip_addresses = []
          dns_names = []

          # For each of the found addresses
          result.answer.map do |resource|
            next if resource.type == Dnsruby::Types::RRSIG # TODO parsing this out is a pain, not sure if it's valuable
            next if resource.type == Dnsruby::Types::NS
            next if resource.type == Dnsruby::Types::TXT # TODO - let's parse this out?

            ip_addresses << resource.address.to_s if resource.respond_to? :address
            dns_names << resource.domainname.to_s if resource.respond_to? :domainname
            dns_names << resource.name.to_s.downcase
          end # end result.answer

        rescue Dnsruby::SocketEofResolvError => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ServFail => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::NXDomain => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ResolvTimeout => e
          _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
        rescue Errno::ENETUNREACH => e
          _log_error "Hit exception: #{e}. Are you sure you're connected?"
        end

        _log_good "Got... #{ip_addresses.concat(dns_names)}"

        ip_addresses.concat(dns_names)
      end

    end
  end
end
