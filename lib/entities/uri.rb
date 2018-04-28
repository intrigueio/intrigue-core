module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Uri",
      :description => "A Website or Webpage",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    "Server: #{details["server_fingerprint"].to_a.join("; ")} | " +
    "App: #{details["app_fingerprint"].to_a.join("; ")} | " +
    "Title: #{details["title"]}"
  end

end
end
end
