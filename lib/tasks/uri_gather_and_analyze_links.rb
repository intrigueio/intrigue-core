module Intrigue
module Task
class UriGatherAndAnalyzeLinks  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_gather_and_analyze_links",
      :pretty_name => "URI Gather And Analyze Links",
      :authors => ["dan_geer","jcran"],
      :description => "This task parses the main page and performs analysis on links.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","Uri"]
    }
  end

  def run
    super

    uri = _get_entity_name
    _log "Connecting to #{uri} for #{@entity}"

    # Go collect the page's contents
    _log "Gathering contents"
    contents = http_get_body(uri)

    return _log_error "Unable to retrieve uri: #{uri}" unless contents

    ###
    ### Now, parse out all links and do analysis on the individual links
    ###
    _log "Parsing out DNS names from links"
    original_dns_records = []
    URI.extract(contents, ["https","http"]) do |link|
      begin

        # Collect the host
        host = URI(link).host

        _create_entity "Uri", "name" => link, "uri" => link
        _create_entity "DnsRecord", "name" => host

        # Add to both arrays, so we can keep track of the original set, and a resolved set
        original_dns_records << host

      rescue URI::InvalidURIError => e
        _log_error "Error, unable to parse #{link}"
      end
    end

    ###
    ### Now group the original hosts into a hash of each item and a count
    ###
    # http://stackoverflow.com/questions/20386094/ruby-count-array-objects-if-object-includes-value
    _log "Collecting DNS name counts"
    grouped_original_dns_records = original_dns_records.inject(Hash.new(0)) do |hash,element|
      hash[element] +=1 if hash[element]
      hash
    end

    ###
    ### Iterate through the original collection
    ###
    _log "Displaying DNS name counts"
    grouped_original_dns_records.sort_by{|x| x.last }.reverse.each do |dns_record,count|
      # Create an entity for each record
      #_create_entity "DnsRecord", "name" => dns_record
      # Display the analysis in the logs
      _log "#{count} #{dns_record}"
    end
    ###

    total_hrefs = 0
    grouped_original_dns_records.map{|result| total_hrefs += result.last }
    _log "#{total_hrefs} hrefs across #{grouped_original_dns_records.count} dns records"
    _log ""
    _log "---"
    _log ""


    ###
    ### For each of the hostnames, let's resolve them out
    ###
    _log "Resolving DNS Names"
    grouped_resolved_dns_records = {}
    #x = grouped_original_dns_records.clone
    grouped_original_dns_records.each do |host,count|

      # handle any weirdness
      next unless host

      #  Resolve any CNAME records. Keep these separate for analysis purposes
      cnames = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::CNAME)

      #x[:cnames] = cnames

      # If there are cname records
      if cnames.count > 0
        cnames.each do |r|
          _log "#{host}"
          _log " --> #{r.name.to_s}"

          # add an item to the hash
          grouped_resolved_dns_records[r.name.to_s] = count
        end
      else #otherwise
        grouped_resolved_dns_records[host] = count
      end
    end

    #_log "X! #{x}"

    _log ""
    _log "---"
    _log ""

    ###
    ### Iterate through the resolved collection
    ###
=begin
    _log "Displaying resolved DNS Names"
    grouped_resolved_dns_records.sort_by{|x| x.last }.reverse.each do |dns_record,count|
      # Create an entity for each record
      #_create_entity "DnsRecord", "name" => dns_record
      # Display the analysis in the logs
      _log "#{count} #{dns_record}"
    end
    _log "#{total_hrefs} hrefs across #{grouped_resolved_dns_records.count} dns records"

    _log ""
    _log "---"
    _log ""
=end

    ###
    ### Now, resolve those hosts into IPs, and see how deep it goes
    ###
    _log "Resolving IP addresses from the original links"
    ip_addresses = []
    grouped_original_dns_records.each do |dns_record,count|

      # handle any weirdness
      next unless dns_record

      begin
        # Get the addresses
        Resolv.new.getaddresses(dns_record).each do |ip|
          #_log "Resolved #{dns_record} into #{ip}"
          ip_addresses << { :host => ip, :dns_record => dns_record }
        end

        # XXX - we should probably .getaddresses() a couple times to deal
        # with round-robin DNS & load balancers. We'd need to merge results
        # across the queries

      rescue Exception => e
        _log_error "Hit exception: #{e}"
      end
    end


    ###
    ### Now group the addresses into collections based on ip
    ###
    _log "Collecting IP address counts"
    grouped_ip_records = ip_addresses.inject(Hash.new(0)) do |hash,element|
      hash[element] +=1 if hash[element]
      hash
    end

    ###
    ### Verbose Info
    ###
    _log "Displaying IP address counts"
    grouped_ip_records.sort_by{|x| x.last }.reverse.each do |record,count|
      _create_entity "IpAddress", "name" => record[:host], "description" => record[:dns_record]
      _log "#{count} #{record}"
    end

    total_ips = 0
    grouped_ip_records.map{|result| total_ips += result.last }
    _log "#{total_ips} IPs across #{grouped_resolved_dns_records.count} dns records"

  end

end
end
end
