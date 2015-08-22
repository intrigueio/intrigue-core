module Intrigue
module Entity
class SslCertificate < Base

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
