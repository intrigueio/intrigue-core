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

      # if we don't have a list, safe to return false now
      return false unless additional_exception_list

      puts "EXCEPTION DEBUG: #{type_string}##{entity_name}"
      puts "EXCEPTION DEBUG: #{additional_exception_list.count} exceptions"

      # check additional exception strings
      is_an_exception = false
      additional_exception_list.each do |x|
        return true if entity_name.downcase =~ /#{x.downcase}/
      end

    false
    end

end
end
end
end
