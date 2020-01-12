module Intrigue
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
    def self.create_by_type(requested_type, issue_model_details, instance_specifics)
      
      # first look thorugh our issue types and get the right one
      issue_type = @issue_types.select{ |h| h.metadata[:name] == requested_type }.first
      unless issue_type 
        raise "Unknown issue type: #{requested_type}"
        return
      end
    
      issue_instance_details = issue_type.metadata.merge!(instance_specifics)
      
      combined_issue_details = issue_model_details.merge({
        name: issue_type.metadata[:name],
        #type: issue_type.metadata[:type],
        pretty_name: issue_type.metadata[:pretty_name],
        status: issue_type.metadata[:status],
        severity: issue_type.metadata[:severity],
        category: issue_type.metadata[:category],
        #description: issue_type.metadata[:description],
        #references: issue_type.metadata[:references],
        details: issue_instance_details})
 
      # then create the darn thing
      issue = issue_type.create(combined_issue_details)
    
    issue
    end
  
  end
  end
  