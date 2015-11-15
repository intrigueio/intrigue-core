module Intrigue
module Entity
class DnsServer < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end

  def validate
    @name =~ /^[a-zA-Z0-9\.].*/
  end

end
end
end
