module Intrigue
module Entity
class IpAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "An IP Address",
      :user_creatable => true
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex)
  end

  def primary
    false
  end

  def detail_string

    top_os_string = details["os"].to_a.first.match(/(.*)(\ \(.*\))/)[1] if details["os"].to_a.first
    port_string = "(" + details["ports"].count.to_s + ")" if details["ports"]

    "#{top_os_string} | #{details["provider"]} | port_string"
  end

end
end
end
