module Intrigue
module Task
class SearchDnsimple < BaseTask

    def self.metadata
      {
        :name => "search_dnsimple",
        :pretty_name => "Search DnSimple Zone",
        :authors => ["Anas Ben Salah"],
        :description => "This task queries Dnsimple API for DnsRecord and Domains related the domain to investigate ",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
        :allowed_options => [],
        :created_types => ["Domain", "DnsRecord"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name

      # Make sure the key is set
      api_key = _get_task_config("dnsimple_api_key")
      account_id = _get_task_config("dnsimple_account_id")
      # Obtain your API token and Account ID
      # https://support.dnsimple.com/articles/api-access-token/
      dnsimple = Dnsimple::Client.new(
        access_token: api_key
      )

      # List all domains in account
      dnsimple.domains.list_domains(account_id).data.each do |domain|
        #create domain entity for all domains related to the account_id
        _create_entity("Domain", {"name" => domain.name})

        #this should be optional...
        #Create issue if the domain will expire in 30 days
        # if ((Date.parse(domain.expires_on)- DateTime.now).to_i) < 30
        #   _create_issue({
        #     name: "Domain name will be expired soon",
        #     type: "Domain expired",
        #     category: "network",
        #     severity: 2,
        #     status: "confirmed",
        #     description: "this domain will expire soon you have to renew the license if you want to keep it",
        #     details: domain.expires_on
        #   })
        # end
      end

      #initialize records to nil
      records = nil

      # Get all records on zone
      records = dnsimple.zones.list_zone_records(account_id,entity_name)

      #check if record is not nil
      if records
      # List all records on zone
        records.data.each do |dns|
          if (dns.content =~ dns_regex) == 0
            _create_entity("Nameserver", {"name" => dns.content , "created_at" => dns.created_at})
          elsif(dns.content =~ ipv4_regex || dns.content =~ ipv6_regex)
            _create_entity("IpAddress", {"name" => dns.content ,"details" => dns.name})
          end
        end
      # Log error
      else
        _log_error "Zone #{entity_name} not found"
      end

    end #end run

end
end
end
