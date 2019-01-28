module Intrigue
module Task
class DnsBruteTld < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_brute_tld",
      :pretty_name => "DNS TLD Bruteforce",
      :authors => ["jcran"],
      :description => "DNS TLD Bruteforce",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord","String"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "use_file", :regex => "boolean", :default => false },
        {:name => "data_file", :regex => "filename", :default => "public_suffix_list.clean.txt" }
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Find more info here:
    # http://www.icann.org/en/tlds/

    basename = _get_entity_name

    opt_use_file = _get_option "use_file"
    opt_filename = _get_option "data_file"

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      _log "Using file #{opt_filename}"
      tld_list = File.open("#{$intrigue_basedir}/data/#{opt_filename}","r").read.split("\n")
      tld_list = tld_list.map {|x| x.downcase }
    else
      _log "Using built-in list"
      tld_list = File.open("#{$intrigue_basedir}/data/tlds-alpha-by-domain.txt","r").read.split("\n")
      tld_list = tld_list.map {|x| x.downcase }
    end

    _log_good "Using TLD list: #{tld_list}"

    resolved_addresses = []

    tld_list.each do |tld|
      begin

        # Calculate the domain name
        domain = "#{basename}.#{tld}"

        # Try to resolve
        resolved_address = resolve_name(domain)

        # If we resolved, create the right entities
        if resolved_address
        _log_good "Resolved Address #{resolved_address} for #{domain}"
          _create_entity("DnsRecord", {"name" => domain})
        end

      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      rescue Exception => e
        _log_error "Hit exception: #{e}"
      end
    end
  end

end
end
end
