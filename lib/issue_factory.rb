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
      # Provide the full list of issues
      #
      def self.issue_by_type(name)
        x = self.issues.find{|x| x if x.generate({})[:name] == name }
      x.generate({}) if x
      end

      #
      # Returns an issue name if the check matches a inference:[CVE_ID]
      #
      def self.get_issue_by_cve_identifier(cve_id)
        self.issues.each do |h|
          # generate the instances
          issue_metadata = h.generate({})
          next unless issue_metadata[:identifiers]
          if issue_metadata[:identifiers].include?({type: "CVE", name: "#{cve_id}"})
            return issue_metadata
          end
        end
      false
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
      # Provide the full list of issues, given a vendor, product
      #
      def self.checks_for_vendor_product(vendor,product)

        ### First, get all issues with their affected software
        mapped_issues = []
        self.issues.each do |h|
          # generate the instances
          hi = h.generate({});
          # then get all instaces of affected software with issues names
          as = (hi[:affected_software] || [])

          # first check to see if there's an explicit task specified in the issue
          # and if there's not default to the name of the issue (it's probably a check and
          # ... checks are automatically named by their issue thanks to introspection magic)
          mapped_issues << as.map{|x| x.merge({ check_name: (hi[:task]||hi[:name]) }) }
        end


        ## pull out only items that have an affected software that matches our
        ## passed-in vendor / product and only return the name of the task/check to be run
        checks = mapped_issues.flatten.select{|x| x[:vendor] == vendor && x[:product] == product}.map{|x| x[:check_name] }

      # return only those checks that actually exist. this is due to the magical
      # nature of how we select tasks above - which might mean that we pulled in an
      # issue that did not have a corresponding check or task
      checks.map{|x| x if Intrigue::TaskFactory.include?(x) }.compact.uniq
      end

      #
      # Find issue based on check value
      #
      def self.find_issue_by_check(check)

        self.issues.each do |h|
          # generate the instances
          hi = h.generate({});
          if hi[:check] == check
            return hi
          end
        end
        nil
      end


      #
      # Check to see if this handler exists (check by type)
      #
      def self.include?(name)
        @issue_types.each { |h| return true if "#{h.generate({})[:name]}" == "#{name}" }
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

        sanitized_details = instance_specifics.sanitize_unicode
        issue_instance_details = issue_type.generate(sanitized_details)

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