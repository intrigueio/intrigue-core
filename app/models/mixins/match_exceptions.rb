module Intrigue
module Model
module Mixins
module MatchExceptions

    # Method gives us a true/false, depending on whether the entity is in an
    # exception list. Currently only used on project, but could be included
    # in task_result or scan_result. Note that they'd need the "additional_exception_list"
    # and "use_standard_exceptions" fields on the object
    def exception_entity?(entity_name, type_string=nil)

      # Check standard exceptions first
      # (which now live in Intrigue::Ident::TraverseExceptions)
      return true if non_traversable?(entity_name,type_string)

      # check additional exception strings
      is_an_exception = false
      self.additional_exception_list.each do |x|
        is_an_exception = true if entity_name =~ /#{x}/
      end

    is_an_exception
    end

end
end
end
end
