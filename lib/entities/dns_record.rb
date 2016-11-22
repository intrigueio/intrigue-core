module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*/
  end

end
end
end
