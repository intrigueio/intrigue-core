module Intrigue
module Core
module System
module ParseableFormat

  def alienvault_otx_csv_to_entities(filename)

    entities = []
    file_lines = csv_file_to_array filename
    return unless file_lines

    puts 'Parsing Alienvault file'
    file_lines.each do |l|

      next if l =~ /^Indicator type,Indicator,Description\r\n$/

      # strip out the data
      split_line = l.split(",").map{|x| x.strip }
      et = split_line[0] # indicator type
      en = split_line[1] # indicator

      # start here
      modified_et = et.capitalize

      # translate
      modified_et = "Uri" if modified_et == "Url"
      modified_et = "DnsRecord" if modified_et == "Hostname"
      modified_et = "IpAddress" if modified_et == "Ipv4"
      modified_et = "IpAddress" if modified_et == "Ipv6"

      entities << {entity_type: "#{modified_et}", entity_name: "#{en}" }
    end
  end

  def core_csv_to_entities(filename)

    entities = []
    file_lines = csv_file_to_array filename
    return unless file_lines

    puts 'Parsing Standard entity file'
    file_lines.each do |l|

      next if l[0] == "#" # skip comment or header lines
      next if l =~ /^TYPE.*$/i

      # strip out the data
      et, en = l.split(",").map{|x| x.strip}

      entities << {entity_type: "#{et}", entity_name: "#{en}", }
    end
  entities
  end

  # Lines!
  def binary_edge_jsonl_to_entities(filename)
    entities = []
    lines = File.readlines(filename)

    # do ip_adress
    lines.each do |l|

      json  = JSON.parse(l)
      t = json["target"]

      #entities << {entity_type: "Intrigue::Entity::IpAddress", entity_name: "#{t["ip"]}", }

      if "#{t["port"]}" =~ /80$/ || t["port"] =~ /443$/
        scheme = "http"
        scheme = "https" if t["port"] == ~/443$/

        # ipv6
        if t["ip"] =~ /:/
          ip = "[#{t["ip"]}]"
        else
          ip = t["ip"]
        end

        entities << {entity_type: "Intrigue::Entity::Uri", entity_name: "#{scheme}://#{ip}:#{t["port"]}" }
      else
        entities << {entity_type: "Intrigue::Entity::NetworkService", entity_name: "#{t["ip"]}:#{t["port"]}/#{t["protocol"]}" }
      end

    end

  entities
  end

  def intrigueio_csv_to_entities(filename)

    entities = []
    file_lines = csv_file_to_array filename
    return unless file_lines

    puts 'Parsing Intrigue.io Bulk Fingerprint file'
    file_lines.each do |l|

      next if l =~ /^collection, entity type, entity name/i
      next if l =~ /^TYPE.*$/i

      # strip out the data
      split_line = l.split(",").map{|x| x.strip }
      col = split_line[0] # indicator type
      et = split_line[1] # indicator
      en = split_line[2] # indicator

      entities << {collection: col, entity_type: "#{et}", entity_name: "#{en}"}
    end
  entities
  end

  def shodan_csv_to_entities(filename)

    entities = []
    file_lines = csv_file_to_array filename
    return unless file_lines

    puts 'Parsing shodan file'
    file_lines.each do |l|

        next if l =~ /^IpAddress,Indicator\r\n$/

        # strip out the data
        split_line = l.split(",").map{|x| x.strip }
        et = split_line[0] # indicator type.
        en = split_line[1] # indicator


        # start heres
        modified_et = et.capitalize

        # translate
        modified_et = "IpAddress" if modified_et == "Ipv4"
        modified_et = "IpAddress" if modified_et == "Ipv6"

        entities << {entity_type: "#{modified_et}", entity_name: "#{en}" }
    end

  end

  def shodan_json_to_entities(filename)

    entities = []

    # parse newlines, which each contains a json object
    f = File.open(filename,"r")
    file_lines = f.readlines
    f.close

    # ensure we're sane  with the data we're bringing in
    json_entries = []
    file_lines.each do |l|
      parsed_l = JSON.parse(l)
      json_entries << parsed_l
    end

    puts 'Parsing shodan json file'
    json_entries.each do |je|
      
      # create ip address entities
      if je["ip_str"] =~ ipv4_regex || je["ip_str"] =~ ipv6_regex
        entities << {entity_type: "IpAddress", entity_name: je["ip_str"] }
      end

      # create hostnames
      je["hostnames"].each do |je_host|
        if je_host =~ dns_regex
          entities << {entity_type: "DnsRecord", entity_name: je_host }
        end
      end

    end
    entities
  end

  private

  def parse_json_file(filename)
    f = File.open(filename,"r")
    json = JSON.parse(f.read)
    f.close
  json
  end

  def csv_file_to_array(filename)

    f = File.open(filename,"r")
    file_lines = f.readlines
    f.close

    # ensure we're sane  with the data we're bringing in
    file_lines.each do |l|
      unless l =~ /[\w\d\s\_\-\:\\\/\#\.]+/ # check for entity sanity
        return nil
      end
    end

  file_lines
  end


end
end
end
end