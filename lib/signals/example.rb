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

  def self.metadata
    {
      :name => "Example Signal",
      :description => "Just an example signal that we can look for and match on ."
    }
  end

  def self.match(entity,task_result)
    puts "MATCHING #{entity}"

    if (entity.type_string == "String" && entity.name == "finding_trigger")
      puts "FOUND AN ENTITY"
      Intrigue::Model::Finding.create({ :name => "Example Finding on #{entity.name}",
                                        :details => {},
                                        :entity_id => entity.id,
                                        :project_id => entity.project.id,
                                        :task_result_id => task_result.id,
                                        :severity => 5,
                                        :resolved => false,
                                        :deleted => false })
    end
  end

end
end
end
