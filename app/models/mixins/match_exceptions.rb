module Intrigue
module Model
module Mixins
module MatchExceptions

    # Method gives us a true/false, depending on whether the entity is in an
    # exception list. Currently only used on project, but could be included
    # in task_result or scan_result. Note that they'd need the "additional_exception_list"
    # and "use_standard_exceptions" fields on the object
    def exception_entity?(entity_name, type_string=nil)

      manual_list=["cloudflare.com"]

      # Check standard exceptions first
      # (which now live in Intrigue::Ident::TraverseExceptions)
      if non_traversable?(entity_name,type_string) || manual_list.include?(entity_name)
        #puts "MATCHED STATIC BADLIST"
        return true
      end

      # if we don't have a list, safe to return false now
      return false unless additional_exception_list && !additional_exception_list.empty?

      # check additional exception stringsZSW3
      is_an_exception = false
      additional_exception_list.each do |x|
        # this needs two cases:
        # 1) case where we're an EXACT match (ey.com)
        # 2) case where we're a subdomain of an exception domain (x.ey.com)
        # neither of these cases should match the case: jcpenney.com
        if entity_name.downcase =~ /^#{Regexp.escape(x.downcase)}(:[0-9]*)?$/ ||
          entity_name.downcase =~ /^.*\.#{Regexp.escape(x.downcase)}(:[0-9]*)?$/

          #puts "EXCEPTION ENTITY!!! Entity Name: #{entity_name.downcase}"
          #puts "EXCEPTION ENTITY!!! Regex: #{Regexp.escape(x.downcase)}"
          return true
        end
      end

    false
    end

end
end
end
end
