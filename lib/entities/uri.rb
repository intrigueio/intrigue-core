module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

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

  def enrichment_tasks
    ["enrich/uri", "uri_screenshot"]
  end

end
end
end
