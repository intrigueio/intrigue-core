module Intrigue
module Task
class BaseIssueCheck < BaseTask

  def self.issue_class

    class_name = self.to_s.split(":").last
    issue_class_name = "Intrigue::Issue::#{class_name}"
    return nil unless Intrigue::Issue::IssueFactory.issues.map{|x| x.to_s }.include? issue_class_name
    
    issue_class = eval(issue_class_name)
    
  issue_class
  end

  def self.metadata
    return nil unless issue_class 
     
    issue_class.generate.merge!(check_metadata) 
  end

  def run 
    super
    out = check

    # create linked issue here if we got a truthy value ... make sure to append
    # the output of run to the creatd issue for proof 
    if out 
      _create_linked_issue self.metadata["name"]
    end
  end


end
end
end
