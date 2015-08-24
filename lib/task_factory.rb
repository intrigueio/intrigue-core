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
    available_tasks
  end

  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.include?(name)
    available_tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:name] == name)
        return true # Create a new object and send it back
      end
    end
  false
  end

  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.create_by_name(name)
    available_tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:name] == name)
        return task_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No task by that name!"
  end

  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.create_by_pretty_name(pretty_name)
    available_tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:pretty_name] == pretty_name)
        return task_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No task by that name!"
  end

  private

  def self.available_tasks
    #@available_tasks = @tasks.select{|x| x if x.new.check_external_dependencies } unless @available_tasks
    @tasks
  end

end
end
