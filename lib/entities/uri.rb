module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  include Intrigue::Task::Dns # TODO ... move parse_domain_name up in the heirarchy

  def self.metadata
    {
      :name => "Uri",
      :description => "A link to a website or webpage",
      :user_creatable => true,
      :example => "https://intrigue.io"
    }
  end

  def validate_entity
    name =~ /^https?:\/\/.*$/
  end

  def detail_string
    
    # create fingerprint
    if details["fingerprint"]
      fingerprint_array = details["fingerprint"].map do |x| 
        "#{x['vendor']} #{x['product'] unless x['vendor'] == x['product']} #{x['version']}".strip
      end
      out = "Fingerprint: #{fingerprint_array.join("; ")}" if details["fingerprint"]
    else
      out = ""
    end

    if details["title"]
      out << " | " if out.length > 0
      out << " Title: #{details["title"]}" 
    end

  out
  end


  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed

    ## CHECK IF DOMAIN NAME IS KNOWN
    # =================================    
    host = URI.parse(self.name).to_s
    if !host.is_ip_address?
      domain_name = parse_domain_name(host)
      puts "nope" unless self.project.traversable_entity?(domain_name, "Domain")
    end
      
    
    ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES
    ######################################################
    
    # Check types we'll check for indicators 
    # of in-scope-ness
    #
    scope_check_entity_types = [
      "Intrigue::Entity::Organization",
      "Intrigue::Entity::DnsRecord",
      "Intrigue::Entity::Domain" 
    ]

    if self.project.seeds
      self.project.seeds.each do |s|
        next unless scope_check_entity_types.include? s.type.to_s
        if domain_name =~ /#{Regexp.escape(s.name)}/i
          #_log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    end

  # if we didnt match the above and we were asked, it's still true
  true
  end

  def enrichment_tasks
    ["enrich/uri"]
  end

end
end
end
