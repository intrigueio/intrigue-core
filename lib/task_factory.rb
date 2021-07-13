###
### Task factory: Standardize the creation and validation of tasks
###
module Intrigue
    class TaskFactory
    
      def self.register(klass)
        @tasks = [] unless @tasks
        @tasks << klass
      end
    
      def self.list
        @tasks.select{ |t| t if t.metadata} # only send if we have metadata
      end
    
      def self.allowed_tasks_for_entity_type(entity_type)
        list.select{ |task_class| 
          task_class if task_class.metadata[:allowed_types].include? entity_type}
      end
      #
      # XXX - can :name be set on the class vs the object
      # to prevent the need to call "new" ?
      #
      def self.include?(name)
        list.each do |t|
          return true if (t.metadata[:name] == name)
        end
      false
      end
    
      #
      # XXX - can :name be set on the class vs the object
      # to prevent the need to call "new" ?
      #
      def self.create_by_name(name)
        list.each do |t|
          if (t.metadata[:name] == name)
            return t.new # Create a new object and send it back
          end
        end
        ### XXX - exception handling? This should return a specific exception.
        raise "No task with the name: #{name}!"
      end
  
      def self.class_by_name(name)
        t = list.find{ |t| t.metadata[:name] == name }
           
        ### XXX - exception handling? This should return a specific exception.
        raise "No task with the name: #{name}!" unless t
      t
      end
    
      #
      # XXX - can :name be set on the class vs the object
      # to prevent the need to call "new" ?
      #
      def self.create_by_pretty_name(pretty_name)
        list.each do |t|
          if (t.metadata[:pretty_name] == pretty_name)
            return t.new # Create a new object and send it back
          end
        end
    
        ### XXX - exception handling? Should this return an exception?
        raise "No task with the name: #{name}!"
      end
      
      def self.checks_for_vendor_product(vendor,product)
      checks = []
      list.each do |t|
        if t.metadata.key?(:affected_software)
          t.metadata[:affected_software].each do |taf|
            if taf[:vendor] == vendor && taf[:product] == product
              checks << t
              break
            end
          end
        end
      end
      checks.compact.uniq
      end
  
    end
end