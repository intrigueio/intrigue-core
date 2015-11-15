module Intrigue
module Entity
class SslCertificate < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/
  end

end
end
end
