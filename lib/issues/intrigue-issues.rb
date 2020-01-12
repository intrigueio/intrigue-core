
# 
# First, a simple factory interface
#
module Intrigue
module Issue
class IssueFactory

  #
  # Register a new handler
  #
  def self.register(klass)
    @issue_types = [] unless @issue_types
    @issue_types << klass if klass
  end

  #
  # Provide the full list of issues
  #
  def self.issues
    @issue_types
  end

  #
  # Check to see if this handler exists (check by type)
  #
  def self.include?(type)
    @issue_types.each { |h| return true if "#{h.metadata[:name]}" == "#{type}" }
  false
  end

  #
  # create_by_type(type)
  #
  # Takes:
  #  type - String
  #
  # Returns:
  #   - A handler, which you can call generate on
  #
  def self.create_instance_by_type(requested_type, issue_model_details, instance_specifics)
    
    # first look thorugh our issue types and get the right one
    issue_type = @issue_types.select{ |h| h.generate({})[:name] == requested_type }.first
    unless issue_type 
      raise "Unknown issue type: #{requested_type}"
      return
    end
  
    issue_instance_details = issue_type.generate(instance_specifics)

    issue_model = issue_model_details.merge({
      name: issue_instance_details[:name],
      pretty_name: issue_instance_details[:pretty_name],
      status: issue_instance_details[:status],
      severity: issue_instance_details[:severity],
      category: issue_instance_details[:category],
      #description: issue_type.metadata[:description],
      #references: issue_type.metadata[:references],
      details: issue_instance_details})

    # then create the darn thing
    issue = Intrigue::Model::Issue.create(issue_model)
  
  issue
  end

end
end
end


# 
# Then, a simple base issue, which helps subclasses registers with the above
#
module Intrigue
module Issue
class BaseIssue
  def self.inherited(base)
    Intrigue::Issue::IssueFactory.register(base)
    super
  end
end
end
end

#
# Finally, source in all the issues, becasue this lets this folder stand 
# alone and be published as a gem (since it's helpful to get this info out in the world)
#
issues_folder= File.expand_path('..', __FILE__) # get absolute directory
puts "Sourcing intrigue issues from  #{issues_folder}"
Dir["#{issues_folder}/*.rb"].each {|f| require_relative f}
