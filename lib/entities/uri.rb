module Intrigue
module Entity
class Uri < Intrigue::Core::Model::Entity

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

    # only scope in stuff that's not hidden
    return false if self.hidden

  # if we didnt match the above and we were asked, it's still true
  true
  end

  def enrichment_tasks
    ["enrich/uri", "enrich/uri_browser", "uri_check_api_endpoint", "uri_extract_linked_hosts"]
  end

end
end
end
