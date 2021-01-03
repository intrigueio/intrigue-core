module Intrigue
module Entity
class ApiEndpoint < Intrigue::Core::Model::Entity
  
  def self.metadata
    {
      :name => "ApiEndpoint",
      :description => "A http based api endpoint",
      :user_creatable => true,
      :example => "https://app.intrigue.io/api"
    }
  end

  def validate_entity
    name.match /^https?:\/\/.*$/
  end

  def detail_string
    
    # create fingerprint
    if details["fingerprint"]
      fingerprint_array = details["fingerprint"].map do |x| 
        "#{x['vendor']} #{x['product'] unless x['vendor'] == x['product']} #{x['version']}".strip
      end
      out = "Fingerprint: #{fingerprint_array.sort.uniq.join("; ")}" if details["fingerprint"]
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
    return true if self.allow_list
    return false if self.deny_list

  # if we didnt match the above and we were asked, it's still true
  true
  end

  def enrichment_tasks
    ["enrich/api_endpoint"]
  end

end
end
end
