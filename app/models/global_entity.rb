module Intrigue
module Core
module Model

  class GlobalEntity < Sequel::Model
    plugin :validation_helpers
    plugin :timestamps

    self.raise_on_save_failure = false

    def validate
      super
      validates_unique([:namespace, :type, :name])
    end

    def self.exists?(type_string,entity_name)
      # now form the query, taking into acount the filter if we can
      found_entity = Intrigue::Core::Model::GlobalEntity.first(type: type_string, name: entity_name)
    end

    def self.load_global_namespace(data)
      (data["entities"] || []).each do |x|
        Intrigue::Core::Model::GlobalEntity.update_or_create({
          :name => x["name"],
          :type => "#{x["type"]}".split(":").last, # shorten to just the type_string
          :namespace => x["namespace"]
        })
      end
    end

    def self.scope_verification_types
      scope_verification_types = [
        "DnsRecord",
        "Domain",
        "EmailAddress",
        "Organization",
        "Nameserver",
        "NetBlock",
        "Uri",
        "UniqueKeyword",
        "UniqueToken",
        "IpAddress"
      ]
    end

  end

end
end
end