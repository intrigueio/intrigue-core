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
  # Provide the full list of issues, given a 
  #
  def self.issues_for_vendor_product(vendor,product)
    
    ### First, get all issues with their affected software
    mapped_issues = []
    self.issues.each do |h| 
      # generate the instances
      hi = h.generate({}); 
      # then geet all instaces of affected software with issues names
      as = (hi[:affected_software] || [])
      mapped_issues << as.map{|x| x.merge({ :name => hi[:name] }) }
    end

  mapped_issues.flatten.select{|x| x[:vendor] == vendor && x[:product] == product}.map{|x| x[:name] }.uniq.compact
  end

  #
  # Provide the full list of issues, given a 
  #
  def self.checks_for_vendor_product(vendor,product)
    
    ### First, get all issues with their affected software
    mapped_issues = []
    self.issues.each do |h| 
      # generate the instances
      hi = h.generate({}); 
      # then geet all instaces of affected software with issues names
      as = (hi[:affected_software] || [])
      mapped_issues << as.map{|x| x.merge({ :check => hi[:check] }) }
    end

  mapped_issues.flatten.select{|x| x[:vendor] == vendor && x[:product] == product}.map{|x| x[:check] }.uniq.compact
  end


  #
  # Check to see if this handler exists (check by type)
  #
  def self.include?(type)
    @issue_types.each { |h| return true if "#{h.generate({})[:name]}" == "#{type}" }
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
  def self.create_instance_by_type(requested_type, issue_model_details, instance_specifics={})
    
    # first look thorugh our issue types and get the right one
    issue_type = self.issues.select{ |h| h.generate({})[:name] == requested_type }.first
    unless issue_type 
      raise "Unknown issue type: #{requested_type}"
      return
    end
  
    issue_instance_details = issue_type.generate(instance_specifics)

    # add in the fields we want to use when querying... 
    issue_model = issue_model_details.merge({
      name: issue_instance_details[:name],
      source: issue_instance_details[:source]
    })

    # then create the darn thing
    issue = Intrigue::Core::Model::Issue.update_or_create(issue_model)
    
    # save the specifics 
    issue.description = issue_type.generate({})[:description]
    issue.pretty_name = issue_instance_details[:pretty_name]
    issue.status = issue_instance_details[:status]
    issue.severity = issue_instance_details[:severity]
    issue.category = issue_instance_details[:category]
    issue.remediation = issue_type.generate({})[:remediation]
    issue.references = issue_type.generate({})[:references]
    issue.details = issue_instance_details
    issue.save_changes
  
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

  def self.export_hash
    generate({})
  end

  def self.export_json
    generate({}).to_json
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
Dir["#{issues_folder}/issues/*.rb"].each {|f| require_relative f}
