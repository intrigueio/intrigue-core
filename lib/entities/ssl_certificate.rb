module Intrigue
module Entity
class SslCertificate < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SslCertificate",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
