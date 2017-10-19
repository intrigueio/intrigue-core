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

    to_return = ""

    if details["lookup_data"]
      to_return = details["lookup_data"].map{|x| x["name"] }.sort.uniq.join(", ")
    end

    top_os_string = details["os"].to_a.first.match(/(.*)(\ \(.*\))/)[1] if details["os"].to_a.first
    port_string = "(" + details["ports"].count.to_s + ")" if details["ports"]
    "#{to_return} (#{top_os_string})"
  end

end
end
end
