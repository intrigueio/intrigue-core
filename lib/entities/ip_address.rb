module Intrigue
module Entity
class IpAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "An IP Address"
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex)

    # warn if they don't exist:
    # details["version"]
  end

  def primary
    false
  end

  def detail_string
    top_os_string = details["os"].to_a.first.match(/(.*)(\ \(.*\))/)[1] if details["os"].to_a.first
    port_string = "(" + details["ports"].count.to_s + ")" if details["ports"]
    "#{top_os_string}"
  end

end
end
end
