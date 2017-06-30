module Intrigue
  class Signals
    def self.all
      [Intrigue::Signal::ExampleSignal]
    end
  end
end

module Intrigue
module Signal
class ExampleSignal

  def initialize(entity,task_result)
    @entity = entity
    @task_result = task_result
  end

  def self.metadata
    {
      :name => "Example Signal",
      :description => "Just an example signal that we can look for and match on."
    }
  end

  def match
    true if (@entity.type_string == "String" && @entity.name == "finding_trigger")
  end

  def generate
    Intrigue::Model::Finding.create({ :name => "Example Finding on #{@entity.name}",
                                      :details => {},
                                      :entity_id => @entity.id,
                                      :project_id => @entity.project.id,
                                      :task_result_id => @task_result.id,
                                      :severity => 5,
                                      :resolved => false,
                                      :deleted => false })
  end

end
end
end
