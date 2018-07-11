module Intrigue
  module Task
    module Dns

      # convenience method to just send back name
      def resolve_name(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])
        resolve_names(lookup_name,lookup_types).first
      end

      # convenience method to just send back names
      def resolve_names(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])

        names = []
        x = resolve(lookup_name, lookup_types)
        x.each {|y| names << y["name"] }

      names.uniq
      end

      def resolve(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])

        resolver_name = _get_system_config "resolver"

        begin
          resolver = Dnsruby::Resolver.new(
            :search => [],
            :nameserver => [resolver_name],
            :query_timeout => 5
          )

          results = []
          lookup_types.each do |t|
            begin
              #_log "Attempting lookup on #{lookup_name} with type #{t}"
              results << resolver.query(lookup_name, t)
            rescue Dnsruby::NXDomain => e
            end
          end


          # For each of the found addresses
          resources = []
          results.each do |result|

            # Let us know if we got an empty result
            next if result.answer.empty?

            result.answer.map do |resource|

              next if resource.type == Dnsruby::Types::NS

              resources << {
                "name" => resource.address.to_s,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata,
                  "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :address

              resources << {
                "name" => resource.domainname.to_s.downcase,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata,
                  "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :domainname

              resources << {
                "name" => resource.name.to_s.downcase,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata,
                  "nameservers" => resolver.config.nameserver }]}

            end # end result.answer
          end
        rescue Dnsruby::SocketEofResolvError => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ServFail => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ResolvTimeout => e
          _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
        rescue Errno::ENETUNREACH => e
          _log_error "Hit exception: #{e}. Are you sure you're connected?"
        end

      resources || []
      end

    end
  end
end
