module Intrigue
module Task
class BaseCheck < BaseTask

  def self.issue_class
    class_name = self.to_s.split(":").last
    issue_class_name = "Intrigue::Issue::#{class_name}"
    return nil unless Intrigue::Issue::IssueFactory.issues.map{|x| x.to_s }.include? issue_class_name
    
    issue_class = eval(issue_class_name)
    
  issue_class
  end

  def self.metadata
    return nil unless issue_class    
    issue_metadata = issue_class.generate
    issue_metadata[:pretty_name] = "Vuln Check - #{issue_metadata[:pretty_name]}"
    return issue_metadata.merge!(check_metadata) 
  end

  def run 
    super
    out = check

    # create linked issue here if we got a truthy value ... make sure to append
    # the output of run to the creatd issue for proof 
    if out
      if out.is_a?(Hash) && out.key?(:status)
        _create_linked_issue self.class.metadata[:name], {status: out[:status], proof: out.except(:status)}
      else
        _create_linked_issue self.class.metadata[:name], {proof: out}
      end
    end
  end


end
end
end
