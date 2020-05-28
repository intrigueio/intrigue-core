module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  include Intrigue::Task::Dns # TODO ... move parse_domain_name up in the heirarchys

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
    return true if self.hidden

    ## CHECK IF DOMAIN NAME IS KNOWN
    # =================================    
    hostname = URI.parse(self.name).host.to_s
    if !hostname.is_ip_address?
      domain_name = parse_domain_name(hostname)
      return false unless self.project.traversable_entity?(domain_name, "Domain")
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
