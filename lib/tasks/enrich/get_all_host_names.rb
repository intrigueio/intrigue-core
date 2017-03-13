require 'dnsruby'

module Intrigue
class GetAllHostNames < BaseTask

  def self.metadata
    {
      :name => "get_all_host_names",
      :pretty_name => "Get All Host Names",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["Host"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => []
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    lookup_name = _get_entity_name

    begin
      resolver = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => opt_resolver,
        :search => [])

      result = resolver.query(lookup_name)
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      names = []
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::RRSIG #TODO parsing this out is a pain, not sure if it's valuable
        unless resource.name == @entity.name
          #if (resource.type == Dnsruby::Types::A || resource.type == Dnsruby::Types::AAAA)
          _log "Adding name from: #{resource}"
          names << resource.address.to_s
          names << resource.name.to_s
          #end
        end #end unless
      end #end result.answer

      @entity.update(:details => @entity.details.merge("aliases" => names.sort.uniq))
      @entity.save

    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    #rescue Exception => e
    #  _log_error "Hit exception: #{e}"
    end

    _log "Ran enrichment task!"
  end

end
end
