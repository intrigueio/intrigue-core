module Intrigue
  module Task
    module Dns

      # convenience method to just send back name
      def resolve_name(lookup_name, lookup_type=Dnsruby::Types::ANY)
        resolve_names(lookup_name,lookup_type).first
      end

      # convenience method to just send back names
      def resolve_names(lookup_name, lookup_type=Dnsruby::Types::ANY)

        names = []
        x = resolve(lookup_name, lookup_type)
        x.each {|y| names << y["name"] }

      names.uniq
      end

      def resolve(lookup_name, lookup_type=Dnsruby::Types::ANY)

        begin
          resolver = Dnsruby::Resolver.new(
            :search => [],
            :query_timeout => 5
          )

          begin
            result = resolver.query(lookup_name, lookup_type)
          rescue Dnsruby::NXDomain => e
            return []
          end

          # Let us know if we got an empty result
          return [] if result.answer.empty?

          resources = []

          # For each of the found addresses
          result.answer.map do |resource|
            next if resource.type == Dnsruby::Types::NS

            resources << {
              "name" => resource.address.to_s,
              "lookup_details" => [{
                "request_record" => lookup_name,
                "request_type" => lookup_type.to_s,
                "response_record_type" => resource.type.to_s,
                "response_record_data" => resource.rdata,
                "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :address

            resources << {
              "name" => resource.domainname.to_s.downcase,
              "lookup_details" => [{
                "request_record" => lookup_name,
                "request_type" => lookup_type.to_s,
                "response_record_type" => resource.type.to_s,
                "response_record_data" => resource.rdata,
                "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :domainname

            resources << {
              "name" => resource.name.to_s.downcase,
              "lookup_details" => [{
                "request_record" => lookup_name,
                "request_type" => lookup_type.to_s,
                "response_record_type" => resource.type.to_s,
                "response_record_data" => resource.rdata,
                "nameservers" => resolver.config.nameserver }]}


          end # end result.answer

        rescue Dnsruby::SocketEofResolvError => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ServFail => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ResolvTimeout => e
          _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
        rescue Errno::ENETUNREACH => e
          _log_error "Hit exception: #{e}. Are you sure you're connected?"
        rescue StandardError => e
          _log_error "Unknown error: #{e}"
        end

      resources || []
      end

    end
  end
end
