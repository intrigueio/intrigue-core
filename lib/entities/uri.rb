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
    fingerprint_array = details["fingerprint"].map{|x| "#{x['vendor']} #{x['product'] unless x['vendor'] == x['product']} #{x['version']}".strip} 
    out = "Fingerprint: #{fingerprint_array.join("; ")}" if details["fingerprint"]
    out << " | Title: #{details["title"]}" if details["title"]
  out
  end

  def enrichment_tasks
    ["enrich/uri"]
  end

end
end
end
