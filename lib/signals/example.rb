module Intrigue
module SignalGenerator
class Example

  def self.metadata
    {
      :name => "Example Signal",
      :description => "Just an example signal that we can look for and match on."
    }
  end

  def match
    true if ( @entity.type_string == "String" &&
              @entity.name == "ohsnapitsanexamplesignal" )
  end

  def generate
    s = Intrigue::Model::Signal.create({  :name => "Example Signal",
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
