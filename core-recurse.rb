#!/usr/bin/env ruby
require 'intrigue'
require 'thor'

class CoreRecurse < Thor

  def initialize(*args)
    super
    $intrigue_basedir = File.dirname(__FILE__)
    @server_uri = "http://127.0.0.1:7777/v1"
    @delim = "#"

    # Connect to Intrigue API
    @x = Intrigue.new

    # create an array of results so we can shortcut
    # anything we already know (and not repeat work)
    $results = {}
  end

  desc "start [Type#Entity] [Depth]", "Start Digging"
  def start(entity,depth=3,options=nil)
    entity_hash = _parse_entity entity
    options_list = _parse_options options
    _recurse entity_hash, depth.to_i

    # Print results
    puts "Results:"
    $results.each do |key,value|
      puts "#{key}:"
      puts "#{value["entities"].map{|x| "  #{x["type"]} #{x["attributes"]["name"]}"}.join("\n")}"
    end
  end

  private

    ###
    ### Main "workflow" function
    ###
    def _recurse(entity, depth)

      # Check for bottom of recursion
      return if depth <= 0

      # Check for prohibited entity name
      if entity["attributes"]
        return if is_prohibited entity
      end

      if entity["type"] == "IpAddress"
        ### DNS Reverse Lookup
        _start_task "dns_lookup_reverse",entity,depth
        ### Whois
        _start_task "whois",entity,depth
        ### Shodan
        #_start_task "search_shodan",entity,depth
        ### Scan
        _start_task "nmap_scan",entity,depth
        ### Geolocate
        #_start_task "geolocate_host",entity,depth
      elsif  entity["type"] == "NetBlock"
        ### Masscan
        _start_task "masscan_scan",entity,depth
      elsif entity["type"] == "DnsRecord"
        ### DNS Forward Lookup
        _start_task "dns_lookup_forward",entity,depth
        ### DNS Subdomain Bruteforce
        _start_task "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
      elsif entity["type"] == "Uri"
        ### Get SSLCert
        _start_task "uri_gather_ssl_certificate",entity,depth
        ### Gather links
        _start_task "uri_gather_and_analyze_links",entity,depth
        ### Dirbuster
        _start_task "uri_dirbuster",entity,depth
        ## screenshot
        _start_task "uri_screenshot",entity,depth
        ### spider
        _start_task "uri_spider",entity,depth
      elsif entity["type"] == "String"
        # Brute TLD
        _start_task "dns_brute_tld",entity,depth
      else
        puts "UNHANDLED:  #{entity["type"]} #{entity["attributes"]["name"]}"
        return
      end
    end

    def _start_task(task_name,entity,depth,options=[])
      puts "Calling #{task_name} on #{entity} with options #{options} at depth #{depth}"

      # and run it
      result = @x.start task_name, entity, options

      # XXX - Store the results for later lookup, avoid duplication (which should save a ton of time)
      key = "#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"
      if $results[key]
        puts "ALREADY FOUND: #{$results[key]["entity"]["attributes"]["name"]}"

        ###
        ### TODO find entity and link
        ###
        #old_entity = Neography::Node.find ....
        #node.outgoing(:child) << old_entity

        return
      else
        $results["#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"] = result
      end

      # Get the results and iterate
      result['entities'].each do |result|
        puts "NEW ENTITY: #{result["type"]} #{result["attributes"]["name"]}"

        # create a new node
        #this = Neography::Node.create(
        #  type: y["type"],
        #  name: y["attributes"]["name"],
        #  task_log: y["task_log"] )
        # store it on the current entity
        #node.outgoing(:child) << this

        # recurse!
        _recurse(result, depth-1)
      end

    end

    # List of prohibited entities - returns true or false
    def is_prohibited entity

      #puts "Checking is_prohibited #{entity}"

      if entity["type"] == "NetBlock"
        cidr = entity["attributes"]["name"].split("/").last.to_i
        return true unless cidr >= 22
      else
        return true if (  entity["attributes"]["name"] =~ /google/             ||
                          entity["attributes"]["name"] =~ /g.co/               ||
                          entity["attributes"]["name"] =~ /goo.gl/             ||
                          entity["attributes"]["name"] =~ /android/            ||
                          entity["attributes"]["name"] =~ /urchin/             ||
                          entity["attributes"]["name"] =~ /youtube/            ||
                          entity["attributes"]["name"] =~ /schema.org/         ||
                          entity["attributes"]["description"] =~ /schema.org/  ||
                          entity["attributes"]["name"] =~ /microsoft.com/      ||
                          #entity["attributes"]["name"] =~ /yahoo.com/          ||
                          entity["attributes"]["name"] =~ /facebook.com/       ||
                          entity["attributes"]["name"] =~ /cloudfront.net/     ||
                          entity["attributes"]["name"] =~ /twitter.com/        ||
                          entity["attributes"]["name"] =~ /w3.org/             ||
                          entity["attributes"]["name"] =~ /akamai/             ||
                          entity["attributes"]["name"] =~ /akamaitechnologies/ ||
                          entity["attributes"]["name"] =~ /amazonaws/          ||
                          entity["attributes"]["name"] == "feeds2.feedburner.com")
      end
    false
    end


    # parse out entity from the cli
    def _parse_entity(entity)
      entity_type = entity.split(@delim).first
      entity_name = entity.split(@delim).last

      entity_hash = {
        "type" => entity_type,
        "attributes" => { "name" => entity_name}
      }
    entity_hash
    end

    # Parse out options from cli
    def _parse_options(options)

        return [] unless options

        options_list = options.split(@delim).map do |option|
          { "name" => option.split("=").first, "value" => option.split("=").last }
        end
    options_list
    end
end

CoreRecurse.start
