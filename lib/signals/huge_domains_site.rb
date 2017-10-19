module Intrigue
module SignalGenerator
class HugeDomainsSite

  def self.metadata
    {
      :name => "HugeDomains Dropped Domain",
      :description => "A dropped domain that was picked up by HugeDomains."
    }
  end

  def match
    true if ( @entity.type_string == "Uri" &&
              @entity.details["response_data"].match(/HugeDomains.com/).length > 0 )
  end

  def generate
    s = Intrigue::Model::Signal.create({  :name => "HugeDomains Dropped Domain",
                                          :details => {},
                                          :project_id => @entity.project.id,
                                          :severity => 5,
                                          :resolved => false,
                                          :deleted => false })
    s.entities << @entity
    s.save
  end

end
end
end
