module Intrigue
module Entity
class SslCertificate < Intrigue::Model::Entity

  def metadata
    {
      :type => "SslCertificate",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
