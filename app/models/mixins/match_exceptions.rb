module Intrigue
module Model
module Mixins
module MatchExceptions

    # Method gives us a true/false, depending on whether the entity is in an
    # exception list. Currently only used on project, but could be included
    # in task_result or scan_result. Note that they'd need the "additional_exception_list"
    # and "use_standard_exceptions" fields on the object
    def exception_entity?(entity_name, type_string=nil)

      is_an_exception = false

      # Check standard exceptions first
      # (which now live in Intrigue::Ident::TraverseExceptions)
      if self.use_standard_exceptions
        is_an_exception = true if non_traversable?(entity_name,type_string)
      end

      # check additional exception strings
      #puts "DEBUG: Additional exceptions: #{self.additional_exception_list}"
      if self.additional_exception_list
        self.additional_exception_list.split(",").each do |x|
          is_an_exception = true if entity_name =~ /#{x}/
        end
      end

    is_an_exception
    end

end
end
end
end
