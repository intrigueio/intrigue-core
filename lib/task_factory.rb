###
### Task factory: Standardize the creation and validation of tasks
###
class TaskFactory

  def self.register(klass)
    @tasks = [] unless @tasks
    @tasks << klass if klass
  end

  def self.list
    @tasks
  end

  def self.include?(name)
    @tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:name] == name)
        return true # Create a new object and send it back
      end
    end
  false
  end

  def self.create_by_name(name)
    @tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:name] == name)
        return task_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No task by that name!"
  end

  def self.create_by_pretty_name(pretty_name)
    @tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:pretty_name] == pretty_name)
        return task_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No task by that name!"
  end

end
