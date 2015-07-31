require 'pry'
###
### Task factory: Standardize the creation and validation of tasks
###
class TaskFactory

  def self.register(klass)
    @tasks = [] unless @tasks
    @tasks << klass if klass
  end

  def self.list
    available_tasks
  end

  def self.include?(name)
    available_tasks.each do |t|
      task_object = t.new
      if (task_object.metadata[:name] == name)
        return true # Create a new object and send it back
      end
    end
  false
  end

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
    @tasks.select{|x| x if x.new.check_external_dependencies }
  end

end
